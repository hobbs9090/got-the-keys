require "rails_helper"

RSpec.describe "Api::V1::Properties::Enquiries", type: :request do
  let!(:user)     { create(:user) }
  let!(:property) { create(:property, listing_state: "published") }

  describe "POST /api/v1/properties/:property_id/enquiries" do
    let(:valid_payload) do
      {
        message:     "I'd love to know more about the garden orientation. Could you confirm whether it's south-facing?",
        source_type: "general_enquiry"
      }
    end

    it "creates an enquiry attributed to the authenticated user" do
      expect {
        post "/api/v1/properties/#{property.id}/enquiries",
             params: valid_payload.to_json,
             headers: api_auth_headers(user)
      }.to change(Enquiry, :count).by(1)
      expect(response).to have_http_status(:created)
      enquiry = Enquiry.last
      expect(enquiry.customer_email).to eq(user.email)
      expect(json_body["lead_reference"]).to eq(enquiry.lead_reference)
    end

    it "ignores customer fields supplied in the body" do
      post "/api/v1/properties/#{property.id}/enquiries",
           params: valid_payload.merge(customer_email: "spoof@example.com",
                                        customer_name: "Hacker").to_json,
           headers: api_auth_headers(user)
      expect(Enquiry.last.customer_email).to eq(user.email)
    end

    it "requires authentication" do
      post "/api/v1/properties/#{property.id}/enquiries",
           params: valid_payload.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "404s when property is not publicly visible" do
      hidden = create(:property, :draft)
      post "/api/v1/properties/#{hidden.id}/enquiries",
           params: valid_payload.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end

    it "422s when message is too short" do
      post "/api/v1/properties/#{property.id}/enquiries",
           params: { message: "hi" }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "code")).to eq("validation_failed")
    end
  end
end
