require 'rails_helper'

describe ForSaleController do
  describe "routing" do

    it "routes to #index" do
      expect(get: "/for_sale").to route_to("for_sale#index")
    end

    it "routes to #show" do
      expect(get: "/properties/1").to route_to("properties#show", :id => "1")
    end

  end
end
