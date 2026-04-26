require "rails_helper"

RSpec.describe "Api::V1::SavedSearches", type: :request do
  let!(:user) { create(:user) }

  describe "POST /api/v1/saved_searches" do
    let(:valid_attrs) do
      {
        search_query:    "victorian terrace",
        sale_status:     "for_sale",
        town_city:       "Bristol",
        min_bedrooms:    3,
        min_price_pence: 30_000_000,
        max_price_pence: 60_000_000,
        sort:            "price_asc",
        alerts_enabled:  true
      }
    end

    it "creates a saved search" do
      expect {
        post "/api/v1/saved_searches",
             params: valid_attrs.to_json,
             headers: api_auth_headers(user)
      }.to change(SavedSearch, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json_body["sale_status"]).to eq("for_sale")
      expect(json_body["sort"]).to eq("price_asc")
    end

    it "validates min vs max price" do
      post "/api/v1/saved_searches",
           params: valid_attrs.merge(min_price_pence: 90_000_000).to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/saved_searches/:id" do
    let!(:search) { create(:saved_search, user: user) }

    it "updates" do
      patch "/api/v1/saved_searches/#{search.id}",
            params: { alerts_enabled: false }.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(search.reload.alerts_enabled).to be(false)
    end

    it "404s on someone else's search" do
      other = create(:saved_search)
      patch "/api/v1/saved_searches/#{other.id}",
            params: { alerts_enabled: false }.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/saved_searches/:id" do
    let!(:search) { create(:saved_search, user: user) }

    it "removes the search" do
      expect {
        delete "/api/v1/saved_searches/#{search.id}", headers: api_auth_headers(user)
      }.to change(SavedSearch, :count).by(-1)
    end
  end
end
