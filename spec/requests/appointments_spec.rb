require "rails_helper"

RSpec.describe "Appointments" do
  let(:user) { FactoryBot.create(:user) }
  let(:property) { user.properties.create!(property_attributes(address_line_1: "44 Mount Ephraim")) }

  def next_open_slot(hour: 10, minutes: 0)
    configuration = BookingConfiguration.current
    date = Date.current

    loop do
      candidate = Time.zone.local(date.year, date.month, date.day, hour, minutes)
      return candidate if configuration.open_on?(date) && candidate > Time.current + configuration.lead_time_hours.hours

      date += 1.day
    end
  end

  describe "GET /properties/:property_id/appointments/new" do
    it "renders the booking form" do
      get new_property_appointment_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Book a viewing")
    end
  end

  describe "POST /properties/:property_id/appointments" do
    it "creates a pending appointment and redirects to the secure show page" do
      slot = next_open_slot

      expect do
        post property_appointments_path(property), params: {
          appointment: {
            customer_name: "Nina Hughes",
            customer_email: "nina.hughes@example.com",
            customer_phone: "07700 930005",
            requested_time: slot.iso8601,
            notes: "Please confirm whether parking is allocated."
          }
        }
      end.to change(Appointment, :count).by(1)

      appointment = Appointment.last

      expect(response).to redirect_to(appointment_path(appointment, token: appointment.access_token))
      expect(appointment.status).to eq("pending")
    end
  end

  describe "GET /appointments/:public_reference" do
    it "requires the access token for public viewers" do
      slot = next_open_slot(hour: 11)
      appointment = property.appointments.create!(
        customer_name: "Owen Clark",
        customer_email: "owen.clark@example.com",
        customer_phone: "07700 930006",
        requested_time: slot,
        scheduled_at: slot
      )

      get appointment_path(appointment)
      expect(response).to redirect_to(root_path)

      get appointment_path(appointment, token: appointment.access_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(appointment.public_reference)
    end
  end
end
