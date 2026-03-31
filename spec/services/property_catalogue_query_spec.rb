require "rails_helper"

RSpec.describe PropertyCatalogueQuery do
  it "applies default filters and returns towns from the supplied town scope" do
    sale_in_kent = FactoryBot.create(:property, address_line_1: "1 Sale Lane", town_city: "Sevenoaks")
    sale_in_surrey = FactoryBot.create(:property, address_line_1: "2 Sale Road", town_city: "Guildford")
    FactoryBot.create(:property, :for_rent, address_line_1: "3 Rent Road", town_city: "Croydon")

    result = described_class.new(
      params: { sale_status: Property::SALE_STATUSES[:for_rent] },
      town_scope: Property.for_sale,
      default_filters: { sale_status: Property::SALE_STATUSES[:for_sale] }
    ).call

    expect(result.filters[:sale_status]).to eq(Property::SALE_STATUSES[:for_sale])
    expect(result.scope.to_a).to contain_exactly(sale_in_kent, sale_in_surrey)
    expect(result.available_towns).to match_array(%w[Guildford Sevenoaks])
    expect(result.total_count).to eq(2)
  end

  it "applies text, bedroom, price, town, and sort filters to the catalogue scope" do
    lower_price = FactoryBot.create(
      :property,
      address_line_1: "Harbour Cottage",
      town_city: "Sevenoaks",
      bedrooms: 3,
      asking_price: 550_000,
      property_description: "A Harbour-facing house in Kent with practical family space and a neat rear garden."
    )
    higher_price = FactoryBot.create(
      :property,
      address_line_1: "Harbour House",
      town_city: "Sevenoaks",
      bedrooms: 4,
      asking_price: 725_000,
      property_description: "A Harbour-side home in Kent with larger rooms, strong natural light, and flexible family space."
    )
    FactoryBot.create(
      :property,
      address_line_1: "Meadow View",
      town_city: "Guildford",
      bedrooms: 4,
      asking_price: 740_000,
      property_description: "A Surrey listing with a different location and no Harbour wording in the copy."
    )

    result = described_class.new(
      params: {
        q: "Harbour",
        min_bedrooms: "3",
        min_price: "500,000",
        max_price: "800,000",
        town_city: "Sevenoaks",
        sort: "price_high"
      }
    ).call

    expect(result.filters).to include(
      q: "Harbour",
      min_bedrooms: "3",
      min_price: "500000",
      max_price: "800000",
      town_city: "Sevenoaks",
      sort: "price_high"
    )
    expect(result.properties.to_a.first(2)).to eq([higher_price, lower_price])
    expect(result.total_count).to eq(2)
  end
end
