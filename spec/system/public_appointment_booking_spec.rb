require "rails_helper"

RSpec.describe "Public appointment booking", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.zone.local(2026, 4, 6, 8, 0)) { example.run }
  end

  before do
    configure_booking_rules!(open_weekdays: %w[1 2 3 4 5], office_opens_at: "09:00", office_closes_at: "17:00")
  end

  it "lets a visitor browse to a property and request a viewing" do
    user = FactoryBot.create(:user)
    property = FactoryBot.create(:property, user:, address_line_1: "88 Harbour View")
    requested_slot = property.next_available_slots(limit: 1).first

    visit for_sale_index_path

    expect(page).to have_text("88 Harbour View")
    click_link "88 Harbour View"

    expect(page).to have_current_path(property_path(property))
    expect(page).to have_text("Book a viewing")

    click_link "Request a viewing"

    expect(page).to have_title("Book a viewing for 88 Harbour View")

    within('[data-testid="appointment-form"]') do
      fill_in "appointment_customer_name", with: "Nina Hughes"
      fill_in "appointment_customer_email", with: "nina.hughes@example.com"
      fill_in "appointment_customer_phone", with: "07700 930005"
      find("[data-testid='requested-time-select'] option[value='#{requested_slot.starts_at.iso8601}']").select_option
      fill_in "appointment_notes", with: "Please confirm whether parking is allocated."

      expect do
        click_button "Submit request"
      end.to change(Appointment, :count).by(1)
    end

    appointment = Appointment.order(:created_at).last

    expect(page).to have_text("Appointment request submitted. We will email you with updates.")
    expect(page).to have_text(appointment.public_reference)
    expect(page).to have_text("Pending")
    expect(page).to have_text("88 Harbour View")
    expect(page).to have_text("Nina Hughes")
    expect(page).to have_text("Please confirm whether parking is allocated.")

    expect(appointment.status).to eq("pending")
    expect(appointment.customer_email).to eq("nina.hughes@example.com")
    expect(appointment.requested_time).to eq(requested_slot.starts_at)
  end
end
