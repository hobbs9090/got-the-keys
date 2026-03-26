require "rails_helper"

RSpec.describe "Admin appointments" do
  let(:admin) { FactoryBot.create(:admin, email: "steven@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }
  let(:user) { FactoryBot.create(:user) }
  let(:property) { FactoryBot.create(:property, user:, address_line_1: "9 Park Lane") }

  before do
    sign_in admin
  end

  it "shows the admin-only bookings desk" do
    get admin_bookings_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Bookings desk")
  end

  it "redirects non-admin visitors away from the bookings desk" do
    sign_out admin

    get admin_bookings_path

    expect(response).to redirect_to(new_admin_session_path)
  end

  it "allows an admin to confirm a pending appointment" do
    slot = next_booking_slot
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

    patch transition_admin_appointment_path(appointment, status: "confirmed")

    expect(response).to redirect_to(admin_appointments_path)
    expect(appointment.reload.status).to eq("confirmed")
    expect(appointment.admin).to eq(admin)
  end

  it "renders the appointment detail page in the admin's locale" do
    admin.update!(language: "de")
    slot = next_booking_slot(hour: 11)
    appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Maya Singh",
      customer_email: "maya.singh@example.com",
      customer_phone: "07700 930008",
      requested_time: slot,
      scheduled_at: slot,
      status: "pending"
    )

    get admin_appointment_path(appointment)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Termindetails")
    expect(response.body).to include("Zusammenfassung")
    expect(response.body).to include("Kundenhistorie")
  end

  it "filters the bookings desk by status and customer email" do
    matching_slot = next_booking_slot(hour: 12)
    matching = FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      customer_name: "Filtered Match",
      customer_email: "filtered.match@example.com",
      requested_time: matching_slot,
      scheduled_at: matching_slot
    )
    other_slot = next_booking_slot(hour: 14)
    FactoryBot.create(
      :appointment,
      :pending,
      property:,
      customer_name: "Other Viewer",
      customer_email: "other.viewer@example.com",
      requested_time: other_slot,
      scheduled_at: other_slot
    )

    get admin_bookings_path, params: { status: "confirmed", customer_email: "FILTERED.MATCH@example.com" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(matching.customer_name)
    expect(response.body).not_to include("Other Viewer")
  end
end
