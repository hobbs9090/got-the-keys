require 'rails_helper'

describe PropertiesController do

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'

      response.should be_success
    end
  end

  #describe "GET 'show'" do
  #  it "returns http success" do
  #    get 'show'
  #
  #    response.should be_success
  #  end
  #end
  #
  #describe "POST 'edit'" do
  #  it "returns http success" do
  #    post 'edit'
  #
  #    response.should be_success
  #  end
  #end

end
