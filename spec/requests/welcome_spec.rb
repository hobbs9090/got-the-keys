require 'rails_helper'

RSpec.describe "Welcome", type: :request do
  describe "GET /" do
    it "renders a five-slide homepage hero carousel" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(%r{/assets/hero_4-[^"]+\.jpg})
      expect(response.body).to match(%r{/assets/hero_4@2x-[^"]+\.jpg})
      expect(response.body).to match(%r{/assets/hero_5-[^"]+\.jpg})
      expect(response.body).to match(%r{/assets/hero_5@2x-[^"]+\.jpg})

      document = Nokogiri::HTML.parse(response.body)

      expect(document.css(".orbit-container .orbit-slide").count).to eq(5)
      expect(document.css(".orbit-bullets button").count).to eq(5)
    end
  end
end
