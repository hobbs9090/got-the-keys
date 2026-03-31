require "rails_helper"

RSpec.describe PropertiesHelper, type: :helper do
  let(:user) { FactoryBot.create(:user) }

  describe "#small_image_for" do
    it "includes a 1x and 2x srcset when a matching retina asset exists" do
      property = FactoryBot.create(:property, user:)
      FactoryBot.create(
        :photo,
        property: property,
        image_filename: "sevenoaks_family_home_hero.jpg",
        primary: true,
        position: 1
      )

      markup = helper.small_image_for(property)

      expect(markup).to match(%r{src="/assets/sevenoaks_family_home_hero-[^"]+\.jpg"})
      expect(markup).to match(
        %r{srcset="/assets/sevenoaks_family_home_hero-[^"]+\.jpg 1x, /assets/sevenoaks_family_home_hero@2x-[^"]+\.jpg 2x"}
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
end
