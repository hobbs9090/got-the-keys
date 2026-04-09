require "rails_helper"

RSpec.describe PropertiesHelper, type: :helper do
  let(:user) { FactoryBot.create(:user) }

  describe "#small_image_for" do
    it "includes a 1x and 2x srcset when a matching retina asset exists" do
      property = FactoryBot.create(:property, user:)
      FactoryBot.create(
        :photo,
        property: property,
        image_filename: "properties/property_18_cedar_road_hero.jpg",
        primary: true,
        position: 1
      )

      markup = helper.small_image_for(property)

      expect(markup).to match(%r{src="/assets/properties/property_18_cedar_road_hero-[^"]+\.jpg"})
      expect(markup).to match(
        %r{srcset="/assets/properties/property_18_cedar_road_hero-[^"]+\.jpg 1x, /assets/properties/property_18_cedar_road_hero@2x-[^"]+\.jpg 2x"}
      )
    end

    it "renders a standard image when no matching retina asset exists" do
      property = FactoryBot.create(:property, user:)
      FactoryBot.create(
        :photo,
        property: property,
        image_filename: "gallery-cover.jpg",
        primary: true,
        position: 1
      )

      markup = helper.small_image_for(property)

      expect(markup).to include(%(src="/gallery-cover.jpg"))
      expect(markup).not_to include("srcset=")
    end
  end

  describe "#property_fact_rows" do
    it "includes chronology facts when they are present" do
      property = FactoryBot.build(:property, user:, year_built: 1998, refurbished_year: 2022)

      facts = helper.property_fact_rows(property)

      expect(facts).to include(["Built", 1998], ["Last refurbished", 2022])
    end
  end

  describe "#property_filter_chip_labels" do
    it "uses monthly rental copy for rent filters" do
      chips = helper.property_filter_chip_labels(
        sale_status: Property::SALE_STATUSES[:for_rent],
        min_price: 1_500,
        max_price: 2_500
      )

      expect(chips).to include("Monthly rent from \u00A3#{1_500.to_fs(:delimited)}")
      expect(chips).to include("Monthly rent up to \u00A3#{2_500.to_fs(:delimited)}")
    end
  end

  describe "#listing_state_badge_class" do
    it "keeps sale-status and listing-state badges visually distinct for active deal states" do
      expect(helper.listing_state_badge_class("under_offer")).to eq("badge badge--warning")
      expect(helper.listing_state_badge_class("let_agreed")).to eq("badge badge--warning")
    end
  end

  describe "#property_sale_status_badge_class" do
    it "maps sale statuses to the shared property badge styles" do
      expect(helper.property_sale_status_badge_class(Property::SALE_STATUSES[:for_sale])).to eq("badge badge--accent")
      expect(helper.property_sale_status_badge_class(Property::SALE_STATUSES[:for_rent])).to eq("badge badge--success")
    end
  end

  describe "#property_featured_badge_class" do
    it "uses the shared neutral property badge styling" do
      expect(helper.property_featured_badge_class).to eq("badge badge--neutral")
    end
  end

  describe "#property_card_document_label" do
    it "uses a short brochure label for brochure documents" do
      document = FactoryBot.build(:property_document, category: "brochure", title: "Sales brochure")

      expect(helper.property_card_document_label(document)).to eq("Brochure")
    end
  end
end
