require 'rails_helper'

RSpec.describe "Welcome", type: :request do
  def create_property(user:, address_line_1:, featured:, updated_at:)
    FactoryBot.create(
      :property,
      user:,
      address_line_1:,
      featured:
    ).tap do |property|
      property.update_columns(updated_at: updated_at)
    end
  end

  describe "GET /" do
    it "renders a five-slide homepage hero carousel" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(%r{/assets/hero_4-[^"]+\.jpg})
      expect(response.body).to match(%r{/assets/hero_4@2x-[^"]+\.jpg})
      expect(response.body).to match(%r{/assets/hero_5-[^"]+\.jpg})
      expect(response.body).to match(%r{/assets/hero_5@2x-[^"]+\.jpg})

      document = Nokogiri::HTML.parse(response.body)

      expect(document.css("[data-carousel] [data-carousel-slide]").count).to eq(5)
      expect(document.css(".hero-carousel__bullets button").count).to eq(5)
    end

    it "falls back to the most recently updated properties when no featured listings exist" do
      user = FactoryBot.create(:user)
      older = create_property(user:, address_line_1: "1 Old Mill Lane", featured: false, updated_at: 3.days.ago)
      middle = create_property(user:, address_line_1: "2 Market Street", featured: false, updated_at: 2.days.ago)
      newest = create_property(user:, address_line_1: "3 Harbour View", featured: false, updated_at: 1.day.ago)
      omitted = create_property(user:, address_line_1: "4 Orchard Rise", featured: false, updated_at: 4.days.ago)

      get root_path

      expect(response).to have_http_status(:ok)

      document = Nokogiri::HTML.parse(response.body)
      property_links = document.css('[data-testid^="property-card-link-"]').map { |link| link.text.strip }

      expect(property_links).to eq([newest.address_line_1, middle.address_line_1, older.address_line_1])
      expect(property_links).not_to include(omitted.address_line_1)
    end
  end
end
