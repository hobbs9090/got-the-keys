require "rails_helper"

RSpec.describe "Admin appointments" do
  let(:admin) { FactoryBot.create(:admin, email: "steven@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }
  let(:user) { FactoryBot.create(:user) }
  let(:property) { user.properties.create!(property_attributes(address_line_1: "9 Park Lane")) }

  def next_open_slot(hour: 10)
    configuration = BookingConfiguration.current
    date = Date.current

    loop do
      candidate = Time.zone.local(date.year, date.month, date.day, hour, 0)
      return candidate if configuration.open_on?(date) && candidate > Time.current + configuration.lead_time_hours.hours

      date += 1.day
    end
  end

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
    slot = next_open_slot
    appointment = property.appointments.create!(
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
    slot = next_open_slot(hour: 11)
    appointment = property.appointments.create!(
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
end
