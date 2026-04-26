require "rails_helper"

RSpec.describe "Api::V1::Offers", type: :request do
  let!(:user)         { create(:user) }
  let!(:property)     { create(:property, listing_state: "published") }

  def my_offer(*traits, **overrides)
    create(:offer, *traits, property: property, buyer_email: user.email, **overrides)
  end

  describe "GET /api/v1/offers" do
    it "returns only the user's offers" do
      mine    = my_offer
      _theirs = create(:offer, property: property)

      get "/api/v1/offers", headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      references = json_body["data"].map { |o| o["public_reference"] }
      expect(references).to contain_exactly(mine.public_reference)
    end

    it "filters by status" do
      received = my_offer
      _accepted = my_offer(:accepted)

      get "/api/v1/offers", params: { status: "received" }, headers: api_auth_headers(user)
      references = json_body["data"].map { |o| o["public_reference"] }
      expect(references).to contain_exactly(received.public_reference)
    end

    it "requires authentication" do
      get "/api/v1/offers", headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/offers/:public_reference" do
    it "returns the offer" do
      offer = my_offer
      get "/api/v1/offers/#{offer.public_reference}", headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_body["public_reference"]).to eq(offer.public_reference)
      expect(json_body["amount_pence"]).to eq(offer.amount.to_i)
    end

    it "404s for someone else's offer" do
      other = create(:offer, property: property)
      get "/api/v1/offers/#{other.public_reference}", headers: api_auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/offers/:public_reference/withdraw" do
    it "withdraws a received offer" do
      offer = my_offer
      patch "/api/v1/offers/#{offer.public_reference}/withdraw",
            params: {}.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(offer.reload.status).to eq("withdrawn")
    end

    it "409s when offer is already rejected" do
      offer = my_offer(:rejected)
      patch "/api/v1/offers/#{offer.public_reference}/withdraw",
            params: {}.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:conflict)
      expect(json_body.dig("error", "code")).to eq("conflict")
    end
  end
end
