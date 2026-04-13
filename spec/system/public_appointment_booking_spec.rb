require "rails_helper"

RSpec.describe "Public appointment booking", type: :system, js: true do
  include ActiveSupport::Testing::TimeHelpers

  def dismiss_cookie_banner
    click_button "Reject non-essential" if page.has_button?("Reject non-essential", wait: 1)
  end

  around do |example|
    travel_to(Time.zone.local(2026, 4, 6, 8, 0)) { example.run }
  end

  before do
    configure_booking_rules!(open_weekdays: %w[1 2 3 4 5], office_opens_at: "09:00", office_closes_at: "17:00")
  end

  it "lets a visitor browse to a property and prepare a viewing request" do
    user = FactoryBot.create(:user)
    property = FactoryBot.create(:property, user:, address_line_1: "88 Harbour View")
    requested_slot = property.next_available_slots(limit: 1).first

    visit for_sale_index_path

    expect(page).to have_text("88 Harbour View")
    click_link "88 Harbour View"

    expect(page).to have_current_path(property_path(property))
    dismiss_cookie_banner
    expect(page).to have_text("Book a viewing")

    within('[data-testid="appointment-form"]') do
      find("[data-testid='requested-time-picker-date-#{requested_slot.starts_at.to_date.iso8601}']").click
      find("[data-testid='requested-time-picker'] [data-slot-picker-time='#{requested_slot.starts_at.iso8601}']").click
      expect(find("#appointment_requested_time", visible: false).value).to eq(requested_slot.starts_at.iso8601)
      fill_in "appointment_customer_name", with: "Nina Hughes"
      fill_in "appointment_customer_email", with: "nina.hughes@example.com"
      fill_in "appointment_customer_phone", with: "07700 930005"
      fill_in "appointment_notes", with: "Please confirm whether parking is allocated."
    end

    expect(page).to have_field("appointment_customer_name", with: "Nina Hughes")
    expect(page).to have_field("appointment_customer_email", with: "nina.hughes@example.com")
    expect(page).to have_field("appointment_customer_phone", with: "07700 930005")
    expect(find("#appointment_requested_time", visible: false).value).to eq(requested_slot.starts_at.iso8601)
  end
end
