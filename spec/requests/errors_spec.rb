require "rails_helper"

RSpec.describe "Error pages", type: :request do
  describe "GET /404" do
    it "renders the not-found page with the site navigation header" do
      get "/404"

      document = Nokogiri::HTML.parse(response.body)

      expect(response).to have_http_status(:not_found)
      expect(document.at_css("[data-testid='site-nav']")).to be_present
      expect(document.at_css("[data-testid='site-header']")).to be_present
      expect(response.body).to include("We could not find that page.")
    end

    it "renders the branded not-found content" do
      get "/404"

      expect(response.body).to include("We could not find that page.")
      expect(response.body).to include("Search properties")
      expect(response.body).to include("Return home")
    end
  end
end
