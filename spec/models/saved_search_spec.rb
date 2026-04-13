require "rails_helper"

RSpec.describe SavedSearch do
  it "normalizes filter params for the catalogue query" do
    search = FactoryBot.build(:saved_search, search_query: "garden", town_city: "Westerham", min_bedrooms: 2)

    expect(search.filter_params).to include(
      q: "garden",
      town_city: "Westerham",
      min_bedrooms: 2
    )
  end

  it "strips commas from saved price filters before validation" do
    search = FactoryBot.build(:saved_search, min_price: "600,000", max_price: "700,000")

    expect(search).to be_valid
    expect(search.min_price).to eq(600_000)
    expect(search.max_price).to eq(700_000)
  end

  it "rejects inverted price bounds" do
    search = FactoryBot.build(:saved_search, min_price: 600_000, max_price: 400_000)

    expect(search).not_to be_valid
    expect(search.errors[:max_price]).to include("must be greater than or equal to the minimum price")
  end

  it "requires an associated user" do
    search = FactoryBot.build(:saved_search, user: nil)
    search.email = "orphan@example.com"

    expect(search).not_to be_valid
    expect(search.errors[:user]).to include("must exist")
  end
end
