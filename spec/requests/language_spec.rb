require 'rails_helper'

RSpec.describe "Language switching", type: :request do
  describe "GET /language/new" do
    it "persists a guest Chinese language choice across requests" do
      get new_language_path(language: "zh"), headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)

      get root_path

      expect(response.body).to include("GotTheKeys 帮助业主和房东创建清晰、可信的房源页面")
    end

    it "allows guests to switch to German and renders translated homepage copy" do
      get new_language_path(language: "de"), headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)

      get root_path

      expect(response.body).to include('lang="de"')
      expect(response.body).to include("Immobilien ansehen")
    end

    it "updates the signed-in user preference without requiring profile fields again" do
      user = FactoryBot.create(:user, language: "en")

      sign_in user

      get new_language_path(language: "fr"), headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(user.reload.language).to eq("fr")

      get root_path

      expect(response.body).to include('lang="fr"')
    end

    it "updates the signed-in admin preference and falls back to the homepage when no return path is available" do
      admin = FactoryBot.create(:admin, language: "en")

      sign_in admin

      get new_language_path(language: "zh")

      expect(response).to redirect_to(root_path)
      expect(admin.reload.language).to eq("zh")
    end

    it "redirects back to a safe in-app return path when provided" do
      get new_language_path(language: "it", return_to: properties_path)

      expect(response).to redirect_to(properties_path)
    end

    it "ignores external return paths" do
      get new_language_path(language: "it", return_to: "https://example.com/phish"), headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
    end

    it "ignores protocol-relative return paths" do
      get new_language_path(language: "it", return_to: "//example.com/phish"), headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
    end

    it "rejects unsupported languages" do
      expect do
        get new_language_path(language: "es")
      end.to raise_error(ActionController::BadRequest, "unsupported language")
    end
  end
end
