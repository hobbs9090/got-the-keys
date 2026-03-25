require 'rails_helper'

RSpec.describe "Language switching", type: :request do
  describe "GET /language/new" do
    it "persists a guest language choice across requests" do
      get new_language_path(language: "zh"), headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)

      get root_path

      expect(response.body).to include("GotTheKeys 帮助业主和房东创建清晰、可信的房源页面")
    end

    it "updates the signed-in user preference without requiring profile fields again" do
      user = FactoryBot.create(:user, language: "en")

      sign_in user

      get new_language_path(language: "zh"), headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(user.reload.language).to eq("zh")

      get root_path

      expect(response.body).to include("GotTheKeys 帮助业主和房东创建清晰、可信的房源页面")
    end
  end
end
