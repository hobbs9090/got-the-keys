require "rails_helper"

RSpec.describe "Api::V1::SavedProperties", type: :request do
  let!(:user)     { create(:user) }
  let!(:property) { create(:property, listing_state: "published") }

  describe "POST /api/v1/saved_properties" do
    it "saves a property" do
      expect {
        post "/api/v1/saved_properties",
             params: { property_id: property.id }.to_json,
             headers: api_auth_headers(user)
      }.to change(SavedProperty, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "is idempotent" do
      create(:saved_property, user: user, property: property)
      expect {
        post "/api/v1/saved_properties",
             params: { property_id: property.id }.to_json,
             headers: api_auth_headers(user)
      }.not_to change(SavedProperty, :count)
      expect(response).to have_http_status(:created)
    end

    it "rejects saving own property" do
      mine = create(:property, user: user, listing_state: "published")
      post "/api/v1/saved_properties",
           params: { property_id: mine.id }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "404s for unknown / non-public properties" do
      hidden = create(:property, :draft)
      post "/api/v1/saved_properties",
           params: { property_id: hidden.id }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/saved_properties" do
    it "returns the user's saved properties" do
      create(:saved_property, user: user, property: property)
      get "/api/v1/saved_properties", headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_body["data"].first["id"]).to eq(property.id)
    end

    it "doesn't leak other users' saves" do
      other = create(:user)
      create(:saved_property, user: other, property: property)
      get "/api/v1/saved_properties", headers: api_auth_headers(user)
      expect(json_body["data"]).to be_empty
    end
  end

  describe "DELETE /api/v1/saved_properties/:property_id" do
    it "removes the saved property" do
      create(:saved_property, user: user, property: property)
      expect {
        delete "/api/v1/saved_properties/#{property.id}", headers: api_auth_headers(user)
      }.to change(SavedProperty, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "404s when not previously saved" do
      delete "/api/v1/saved_properties/#{property.id}", headers: api_auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end
end
