require "rails_helper"

RSpec.describe "Appointments" do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:owner) { FactoryBot.create(:user) }
  let(:property) { FactoryBot.create(:property, user: owner, address_line_1: "44 Mount Ephraim") }

  describe "GET /properties/:property_id/appointments/new" do
    around do |example|
      travel_to(Time.zone.local(2026, 4, 9, 8, 0)) { example.run }
    end

    before do
      configure_booking_rules!(open_weekdays: %w[1 2 3 4 5], office_opens_at: "09:00", office_closes_at: "17:00")
    end

    it "redirects back to the property booking panel" do
      sign_in(user)

      get new_property_appointment_path(property)

      expect(response).to redirect_to(property_path(property, anchor: "booking-panel"))
    end

    it "preserves the selected slot when redirecting back to the property page" do
      sign_in(user)
      slot = next_booking_slot

      get new_property_appointment_path(property, slot: slot.iso8601)

      expect(response).to redirect_to(property_path(property, slot: slot.iso8601, anchor: "booking-panel"))
    end

    it "redirects signed-out visitors to sign in before booking" do
      get new_property_appointment_path(property)

      expect(response).to redirect_to(new_user_session_path(return_to: property_path(property, anchor: "booking-panel")))
    end

    it "prefills the booking form for signed-in users on the property page" do
      sign_in(user)

      get new_property_appointment_path(property)
      follow_redirect!

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML.parse(response.body)
      email_input = document.at_css('input[name="appointment[customer_email]"]')

      expect(response.body).to include(%(value="#{ERB::Util.html_escape(user.full_name)}"))
      expect(response.body).to include(%(value="#{ERB::Util.html_escape(user.email)}"))
      expect(response.body).to include(%(value="#{ERB::Util.html_escape(user.mobile_number)}"))
      expect(email_input).to be_present
      expect(email_input["readonly"]).to eq("readonly")
    end

    it "prevents owners from accessing the booking panel redirect" do
      sign_in(owner)

      get new_property_appointment_path(property)

      expect(response).to redirect_to(property_path(property, anchor: "booking-panel"))
      expect(flash[:alert]).to eq(I18n.t("ui.appointments.new.owner_alert"))
    end

    it "includes later slots that are still within the 21-day booking window" do
      sign_in(user)
      late_slot = booking_time(2026, 4, 20, 9, 0)
      FactoryBot.create(
        :availability_window,
        property:,
        kind: "open",
        starts_at: late_slot,
        ends_at: booking_time(2026, 4, 20, 15, 0)
      )

      get new_property_appointment_path(property)
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(value="#{late_slot.iso8601}"))
    end
  end

  describe "POST /properties/:property_id/appointments" do
    it "creates a pending appointment and redirects to the secure show page" do
      sign_in(user)
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

    it "adds the property to saved homes for the signed-in user" do
      sign_in(user)
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
      end.to change(SavedProperty, :count).by(1)

      expect(user.saved_properties.find_by(property: property)).to be_present
    end

    it "ignores a tampered customer email for signed-in users" do
      sign_in(user)
      slot = next_booking_slot

      post property_appointments_path(property), params: {
        appointment: {
          customer_name: "Nina Hughes",
          customer_email: "tampered@example.com",
          customer_phone: "07700 930005",
          requested_time: slot.iso8601,
          notes: "Please confirm whether parking is allocated."
        }
      }

      expect(response).to redirect_to(appointment_path(Appointment.last, token: Appointment.last.access_token))
      expect(Appointment.last.customer_email).to eq(user.email)
    end

    it "does not create duplicate saved homes when already saved" do
      sign_in(user)
      slot = next_booking_slot
      FactoryBot.create(:saved_property, user:, property:)

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
      end.not_to change(SavedProperty, :count)
    end

    it "redirects signed-out visitors to sign in instead of creating an appointment" do
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
      end.not_to change(Appointment, :count)

      expect(response).to redirect_to(new_user_session_path(return_to: property_path(property, anchor: "booking-panel")))
    end

    it "prevents owners from booking a viewing on their own property" do
      sign_in(owner)
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
      end.not_to change(Appointment, :count)

      expect(response).to redirect_to(property_path(property, anchor: "booking-panel"))
      expect(flash[:alert]).to eq(I18n.t("ui.appointments.new.owner_alert"))
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
