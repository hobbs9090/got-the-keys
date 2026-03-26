require "rails_helper"

RSpec.describe "Saved searches", type: :request do
  let!(:matching_property) do
    FactoryBot.create(
      :property,
      town_city: "Sevenoaks",
      bedrooms: 4,
      asking_price: 650_000,
      sale_status: Property::SALE_STATUSES[:for_sale]
    )
  end

  it "stores the current catalogue filters" do
    expect do
      post saved_searches_path, params: {
        saved_search: {
          email: "buyer@example.com",
          locale: "en",
          sale_status: Property::SALE_STATUSES[:for_sale],
          search_query: "family home",
          town_city: "Sevenoaks",
          min_bedrooms: 3,
          min_price: 600_000,
          max_price: 700_000,
          sort: "recommended",
          alerts_enabled: "1"
        }
      }
    end.to change(SavedSearch, :count).by(1)

    expect(response).to redirect_to(properties_path(q: "family home", sale_status: Property::SALE_STATUSES[:for_sale], town_city: "Sevenoaks", min_bedrooms: 3, min_price: 600_000, max_price: 700_000, sort: "recommended"))
    expect(flash[:notice]).to include("1 matching listing")
    expect(matching_property).to be_present
  end
end
