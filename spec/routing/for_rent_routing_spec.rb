require "spec_helper"

describe ForRentController do
  describe "routing" do

    it "routes to #index" do
      get("/for_rent").should route_to("for_rent#index")
    end

    it "routes to #show" do
      get("/properties/1").should route_to("properties#show", :id => "1")
    end

  end
end
