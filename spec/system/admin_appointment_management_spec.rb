require "rails_helper"

RSpec.describe "Admin appointment management", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.zone.local(2026, 4, 6, 8, 0)) { example.run }
  end

  before do
    configure_booking_rules!(open_weekdays: %w[1 2 3 4 5], office_opens_at: "09:00", office_closes_at: "17:00")
  end

  def sign_in_as(admin)
    visit admin_bookings_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: "changeme"
    click_button "Sign in"
    visit admin_bookings_path
  end

  it "lets an admin sign in and confirm a pending appointment from the bookings desk" do
    admin = FactoryBot.create(:admin, email: "bookings-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme")
    user = FactoryBot.create(:user)
    property = FactoryBot.create(:property, user:, address_line_1: "22 Cedar Close")
    slot = next_booking_slot(hour: 14)
    appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Priya Shah",
      customer_email: "priya.shah@example.com",
      customer_phone: "07700 930007",
      requested_time: slot,
      scheduled_at: slot,
      status: "pending"
    )

    sign_in_as(admin)

    expect(page).to have_text("Bookings desk")

    within(find("[data-testid='admin-appointment-row']", text: appointment.customer_name)) do
      click_button "Confirm"
    end

    expect(page).to have_text("Appointment marked as confirmed.")
    expect(page).to have_text("Confirmed")
    expect(appointment.reload.status).to eq("confirmed")
    expect(appointment.admin).to eq(admin)
  end

  it "lets an admin reschedule an appointment from the edit screen" do
    admin = FactoryBot.create(:admin, email: "reschedule-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme")
    user = FactoryBot.create(:user)
    property = FactoryBot.create(:property, user:, address_line_1: "31 Albion Mews")
    FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      requested_time: next_booking_slot(hour: 14),
      scheduled_at: next_booking_slot(hour: 14)
    )
    appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Maya Singh",
      customer_email: "maya.singh@example.com",
      customer_phone: "07700 930008",
      requested_time: next_booking_slot(hour: 16),
      scheduled_at: next_booking_slot(hour: 16),
      status: "pending"
    )
    rescheduled_slot = next_booking_slot(hour: 14, from: Time.zone.local(2026, 4, 6, 17, 1))

    sign_in_as(admin)

    within(find("[data-testid='admin-appointment-row']", text: appointment.customer_name)) do
      click_link "Details"
    end

    within("[data-testid='admin-appointment-header-actions']") do
      click_link "Edit"
    end

    fill_in "appointment_scheduled_at", with: rescheduled_slot.strftime("%Y-%m-%dT%H:%M")
    select "Rescheduled", from: "appointment_status"
    fill_in "appointment_internal_notes", with: "Customer requested a later visit after school pickup."
    click_button "Save changes"

    expect(page).to have_text("Appointment updated.")
    expect(page).to have_text("Rescheduled")
    expect(page).to have_text("Customer requested a later visit after school pickup.")

    expect(appointment.reload.status).to eq("rescheduled")
    expect(appointment.scheduled_at).to eq(rescheduled_slot)
    expect(appointment.admin).to eq(admin)
  end
end
