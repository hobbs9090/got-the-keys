require 'rails_helper'

describe "Properties" do
  describe "GET /properties" do
    it "should retrieve page" do
      get properties_path

      response.status.should be(200)
    end
  end

  describe "GET /properties/1" do
    it "should retrieve page" do
      get property_path(1)

      response.status.should be(200)
    end
  end

  describe "GET /properties/1/photos" do
    it "should retrieve page" do
      get property_photos_path(1)

      response.status.should be(200)
    end
  end

  describe "GET properties/1/floor_plans" do
    it "should retrieve page" do
      get property_floor_plans_path(1)

      response.status.should be(200)
    end
  end

  describe "GET /location/1" do
    it "should retrieve page" do
      get property_photos_path(1)

      response.status.should be(200)
    end
  end

  describe "GET /properties/1.json" do
    it "should retrieve page" do
      get properties_path

      response.status.should be(200)
    end
  end

end
