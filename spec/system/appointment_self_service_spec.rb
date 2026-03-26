require "rails_helper"

RSpec.describe "Appointment self service", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.zone.local(2026, 4, 6, 8, 0)) { example.run }
  end

  before do
    configure_booking_rules!(open_weekdays: %w[1 2 3 4 5], office_opens_at: "09:00", office_closes_at: "17:00")
  end

  it "lets a customer reschedule and cancel with the secure access token" do
    property = FactoryBot.create(:property, address_line_1: "77 Orchard Lane")
    slot = next_booking_slot(hour: 14)
    appointment = FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      customer_name: "Ava Reed",
      customer_email: "ava.reed@example.com",
      customer_phone: "07700 931100",
      requested_time: slot,
      scheduled_at: slot
    )

    visit appointment_path(appointment, token: appointment.access_token)

    click_link "Request a new time"
    find("[data-testid='self-service-slot-select'] option", match: :first).select_option
    click_button "Reschedule viewing"

    expect(page).to have_text("Your viewing has been rescheduled.")

    click_button "Cancel viewing"

    expect(page).to have_text("Your viewing has been cancelled.")
    expect(appointment.reload.status).to eq("cancelled")
  end
end
