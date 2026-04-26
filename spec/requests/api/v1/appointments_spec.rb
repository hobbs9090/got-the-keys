require "rails_helper"

RSpec.describe "Api::V1::Appointments", type: :request do
  let!(:user)     { create(:user) }
  let!(:property) { create(:property, listing_state: "published") }

  def my_appointment(*traits, **overrides)
    create(:appointment, *traits, property: property, customer_email: user.email, **overrides)
  end

  describe "GET /api/v1/appointments" do
    it "returns only the user's appointments" do
      mine  = my_appointment
      _theirs = create(:appointment, property: property)

      get "/api/v1/appointments", headers: api_auth_headers(user)

      expect(response).to have_http_status(:ok)
      references = json_body["data"].map { |a| a["public_reference"] }
      expect(references).to contain_exactly(mine.public_reference)
    end

    it "filters by status" do
      pending  = my_appointment(:pending)
      _confirmed = my_appointment(:confirmed, requested_hour: 11)

      get "/api/v1/appointments", params: { status: "pending" }, headers: api_auth_headers(user)

      references = json_body["data"].map { |a| a["public_reference"] }
      expect(references).to contain_exactly(pending.public_reference)
    end

    it "requires authentication" do
      get "/api/v1/appointments", headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/appointments/:public_reference" do
    it "returns the appointment" do
      appointment = my_appointment
      get "/api/v1/appointments/#{appointment.public_reference}", headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_body["public_reference"]).to eq(appointment.public_reference)
    end

    it "404s for someone else's appointment" do
      other = create(:appointment, property: property)
      get "/api/v1/appointments/#{other.public_reference}", headers: api_auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/appointments/:public_reference/reschedule" do
    it "reschedules within the self-service window" do
      appointment = my_appointment(:confirmed)
      new_time = BookingTimeHelpers.next_booking_slot(hour: 16)
      patch "/api/v1/appointments/#{appointment.public_reference}/reschedule",
            params: { scheduled_at: new_time.iso8601 }.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(appointment.reload.status).to eq("rescheduled")
      expect(appointment.scheduled_at).to be_within(1.minute).of(new_time)
    end

    it "rejects reschedule when self-service has expired" do
      appointment = my_appointment(:confirmed)
      appointment.update_columns(scheduled_at: 2.days.ago, requested_time: 2.days.ago)
      patch "/api/v1/appointments/#{appointment.public_reference}/reschedule",
            params: { scheduled_at: BookingTimeHelpers.next_booking_slot(hour: 15).iso8601 }.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:conflict)
      expect(json_body.dig("error", "code")).to eq("conflict")
    end

    it "422s when scheduled_at is missing" do
      appointment = my_appointment(:confirmed)
      patch "/api/v1/appointments/#{appointment.public_reference}/reschedule",
            params: {}.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/appointments/:public_reference/cancel" do
    it "cancels the appointment" do
      appointment = my_appointment(:confirmed)
      patch "/api/v1/appointments/#{appointment.public_reference}/cancel",
            params: { reason: "Plans changed" }.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(appointment.reload.status).to eq("cancelled")
    end

    it "rejects cancellation when self-service expired" do
      appointment = my_appointment(:confirmed)
      appointment.update_columns(scheduled_at: 2.days.ago, requested_time: 2.days.ago)
      patch "/api/v1/appointments/#{appointment.public_reference}/cancel",
            params: {}.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:conflict)
    end
  end
end
