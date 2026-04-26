require "rails_helper"

RSpec.describe "Api::V1::Properties::Appointments", type: :request do
  let!(:user)     { create(:user) }
  let!(:property) { create(:property, listing_state: "published") }
  let(:scheduled_at) { BookingTimeHelpers.next_booking_slot(hour: 14) }

  describe "POST /api/v1/properties/:property_id/appointments" do
    it "creates an appointment for the authenticated user" do
      expect {
        post "/api/v1/properties/#{property.id}/appointments",
             params: { scheduled_at: scheduled_at.iso8601 }.to_json,
             headers: api_auth_headers(user)
      }.to change(Appointment, :count).by(1)
      expect(response).to have_http_status(:created)
      appointment = Appointment.last
      expect(appointment.customer_email).to eq(user.email)
      expect(json_body["public_reference"]).to eq(appointment.public_reference)
      expect(json_body["status"]).to eq("pending")
    end

    it "rejects bookings on own property" do
      mine = create(:property, user: user, listing_state: "published")
      post "/api/v1/properties/#{mine.id}/appointments",
           params: { scheduled_at: scheduled_at.iso8601 }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "code")).to eq("validation_failed")
    end

    it "requires authentication" do
      post "/api/v1/properties/#{property.id}/appointments",
           params: { scheduled_at: scheduled_at.iso8601 }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "422s for unparseable scheduled_at" do
      post "/api/v1/properties/#{property.id}/appointments",
           params: { scheduled_at: "not-a-date" }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
