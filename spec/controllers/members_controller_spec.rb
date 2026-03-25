require 'rails_helper'

describe MembersController do

  before (:each) do
    @admin = FactoryBot.create(:admin)
    sign_in @admin
  end

  describe "GET 'index'" do
    it "returns http success" do
      get :index

      expect(response).to have_http_status(:ok)
    end
  end

end
