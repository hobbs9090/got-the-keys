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
      expect(response.body).to match(%r{/assets/hero_4-[^"]+\.webp})
      expect(response.body).to match(%r{/assets/hero_4@2x-[^"]+\.webp})
      expect(response.body).to match(%r{/assets/hero_5-[^"]+\.webp})
      expect(response.body).to match(%r{/assets/hero_5@2x-[^"]+\.webp})

      document = Nokogiri::HTML.parse(response.body)

      expect(document.at_css('link[rel="preconnect"][href="https://fonts.googleapis.com"]')).to be_present
      expect(document.at_css('link[rel="preconnect"][href="https://fonts.gstatic.com"][crossorigin]')).to be_present
      expect(document.at_css('link[rel="preload"][as="style"][href*="fonts.googleapis.com/css2"]')).to be_present
      expect(document.at_css('link[rel="stylesheet"][href*="fonts.googleapis.com/css2"][media="print"]')).to be_present
      expect(document.at_css('link[rel="stylesheet"][href*="/assets/public-"]')).to be_present
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

    it "favours image-backed listings when topping up the homepage cards" do
      user = FactoryBot.create(:user)
      image_backed = create_property(user:, address_line_1: "1 Photo Lane", featured: false, updated_at: 3.days.ago)
      newer_text_only = create_property(user:, address_line_1: "2 Text Square", featured: false, updated_at: 1.day.ago)
      another_text_only = create_property(user:, address_line_1: "3 Plain Court", featured: false, updated_at: 2.days.ago)
      FactoryBot.create(:photo, property: image_backed, image_filename: "photo-lane.jpg", primary: true, position: 1)

      get root_path

      document = Nokogiri::HTML.parse(response.body)
      property_links = document.css('[data-testid^="property-card-link-"]').map { |link| link.text.strip }

      expect(property_links.first(3)).to include("1 Photo Lane")
      expect(property_links.index("1 Photo Lane")).to be < property_links.index("2 Text Square")
    end

    it "tops up the homepage cards when there are fewer than three featured listings" do
      user = FactoryBot.create(:user)
      featured_newest = create_property(user:, address_line_1: "1 Featured Lane", featured: true, updated_at: 1.day.ago)
      featured_older = create_property(user:, address_line_1: "2 Featured Close", featured: true, updated_at: 2.days.ago)
      fallback = create_property(user:, address_line_1: "3 Harbour Approach", featured: false, updated_at: 3.hours.ago)
      omitted = create_property(user:, address_line_1: "4 Garden Square", featured: false, updated_at: 2.days.ago)

      get root_path

      expect(response).to have_http_status(:ok)

      document = Nokogiri::HTML.parse(response.body)
      property_links = document.css('[data-testid^="property-card-link-"]').map { |link| link.text.strip }

      expect(property_links).to eq([featured_newest.address_line_1, featured_older.address_line_1, fallback.address_line_1])
      expect(property_links).not_to include(omitted.address_line_1)
      expect(document.css('[data-testid="property-card"]').count).to eq(3)
    end
  end
end
