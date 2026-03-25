require 'rails_helper'

describe "Properties" do
  let!(:user) { User.create!(user_attributes(email: 'request-user@example.com')) }
  let!(:property) { user.properties.create!(property_attributes) }

  describe "GET /properties" do
    it "should retrieve page" do
      get properties_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /properties/1" do
    it "should retrieve page" do
      get property_path(property)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /properties/1/photos" do
    it "should retrieve page" do
      get property_photos_path(property)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET properties/1/floor_plans" do
    it "should retrieve page" do
      get property_floor_plans_path(property)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /location/1" do
    it "should retrieve page" do
      get location_path(property)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /properties/1.json" do
    it "should retrieve page" do
      get "/properties/#{property.id}.json"

      expect(response).to have_http_status(:ok)
    end
  end

end
