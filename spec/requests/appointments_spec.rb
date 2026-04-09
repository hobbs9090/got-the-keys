require "rails_helper"

RSpec.describe "Appointments" do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:property) { FactoryBot.create(:property, user:, address_line_1: "44 Mount Ephraim") }

  describe "GET /properties/:property_id/appointments/new" do
    around do |example|
      travel_to(Time.zone.local(2026, 4, 9, 8, 0)) { example.run }
    end

    before do
      configure_booking_rules!(open_weekdays: %w[1 2 3 4 5], office_opens_at: "09:00", office_closes_at: "17:00")
    end

    it "renders the booking form" do
      get new_property_appointment_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Book a viewing")
    end

    it "prefills the booking form for signed-in users" do
      sign_in(user)

      get new_property_appointment_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(value="#{ERB::Util.html_escape(user.full_name)}"))
      expect(response.body).to include(%(value="#{ERB::Util.html_escape(user.email)}"))
      expect(response.body).to include(%(value="#{ERB::Util.html_escape(user.mobile_number)}"))
    end

    it "includes later slots that are still within the 21-day booking window" do
      late_slot = booking_time(2026, 4, 20, 9, 0)
      FactoryBot.create(
        :availability_window,
        property:,
        kind: "open",
        starts_at: late_slot,
        ends_at: booking_time(2026, 4, 20, 15, 0)
      )

      get new_property_appointment_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(value="#{late_slot.iso8601}"))
    end
  end

  describe "POST /properties/:property_id/appointments" do
    it "creates a pending appointment and redirects to the secure show page" do
      slot = next_booking_slot

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
      slot = next_booking_slot(hour: 11)
      appointment = FactoryBot.create(
        :appointment,
        property:,
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

  describe "self-service management" do
    around do |example|
      travel_to(Time.zone.local(2026, 3, 30, 8, 0)) { example.run }
    end

    it "lets the customer open the self-service reschedule page" do
      appointment = FactoryBot.create(
        :appointment,
        property:,
        requested_time: next_booking_slot(hour: 14),
        scheduled_at: next_booking_slot(hour: 14)
      )

      get edit_self_service_appointment_path(appointment, token: appointment.access_token)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Manage your viewing")
    end

    it "lets the customer reschedule with the secure token" do
      appointment = FactoryBot.create(
        :appointment,
        :confirmed,
        property:,
        requested_time: next_booking_slot(hour: 14),
        scheduled_at: next_booking_slot(hour: 14)
      )
      new_slot = property.next_available_slots(limit: 2, excluding_appointment: appointment).last

      patch reschedule_self_service_appointment_path(appointment, token: appointment.access_token), params: {
        appointment: { requested_time: new_slot.starts_at.iso8601 }
      }

      expect(response).to redirect_to(appointment_path(appointment, token: appointment.access_token))
      expect(appointment.reload.status).to eq("rescheduled")
      expect(appointment.scheduled_at).to eq(new_slot.starts_at)
    end

    it "blocks expired self-service links" do
      appointment = FactoryBot.create(
        :appointment,
        property:,
        requested_time: booking_time(2026, 3, 29, 10, 0),
        scheduled_at: booking_time(2026, 3, 29, 10, 0),
        skip_slot_validation: true
      )

      get edit_self_service_appointment_path(appointment, token: appointment.access_token)

      expect(response).to redirect_to(appointment_path(appointment, token: appointment.access_token))
    end
  end
end
