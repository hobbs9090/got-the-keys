require 'rails_helper'

describe MembersController do

  before (:each) do
    @admin = FactoryBot.create(:admin)
    sign_in @admin
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'

      response.should be_success
    end
  end

end