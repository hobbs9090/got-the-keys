require "spec_helper"

describe ForSaleController do
  describe "routing" do

    it "routes to #index" do
      get("/for_sale").should route_to("for_sale#index")
    end

    it "routes to #show" do
      get("/properties/1").should route_to("properties#show", :id => "1")
    end

  end
end
