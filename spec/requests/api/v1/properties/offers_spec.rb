require "rails_helper"

RSpec.describe "Api::V1::Properties::Offers", type: :request do
  let!(:user)         { create(:user) }
  let!(:sale_property) { create(:property, listing_state: "published") }

  describe "POST /api/v1/properties/:property_id/offers" do
    it "creates an offer attributed to the authenticated user" do
      expect {
        post "/api/v1/properties/#{sale_property.id}/offers",
             params: { amount_pence: 47_500_000, chain_position: "first_time_buyer", notes: "Subject to mortgage." }.to_json,
             headers: api_auth_headers(user)
      }.to change(Offer, :count).by(1)
      expect(response).to have_http_status(:created)
      offer = Offer.last
      expect(offer.buyer_email).to eq(user.email)
      expect(offer.amount).to eq(47_500_000)
      expect(json_body["public_reference"]).to eq(offer.public_reference)
    end

    it "rejects offers on rental properties" do
      rental = create(:property, :for_rent, listing_state: "published")
      post "/api/v1/properties/#{rental.id}/offers",
           params: { amount_pence: 10_000_000 }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "code")).to eq("validation_failed")
    end

    it "requires authentication" do
      post "/api/v1/properties/#{sale_property.id}/offers",
           params: { amount_pence: 47_500_000 }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "422s when amount is missing" do
      post "/api/v1/properties/#{sale_property.id}/offers",
           params: {}.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "404s on unknown / non-public property" do
      hidden = create(:property, :draft)
      post "/api/v1/properties/#{hidden.id}/offers",
           params: { amount_pence: 10_000_000 }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end
end
