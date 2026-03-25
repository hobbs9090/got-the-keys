require 'rails_helper'

describe ForRentController do
  describe "routing" do

    it "routes to #index" do
      expect(get: "/for_rent").to route_to("for_rent#index")
    end

    it "routes to #show" do
      expect(get: "/properties/1").to route_to("properties#show", :id => "1")
    end

  end
end
