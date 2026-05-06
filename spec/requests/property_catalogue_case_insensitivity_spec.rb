require "rails_helper"

RSpec.describe "Property catalogue search (case-insensitive)", type: :request do
  let!(:user) { FactoryBot.create(:user) }

  let!(:for_sale_match) do
    FactoryBot.create(
      :property,
      user:,
      sale_status: Property::SALE_STATUSES[:for_sale],
      address_line_1: "Harbour Cottage",
      town_city: "Sevenoaks"
    )
  end

  let!(:for_sale_other) do
    FactoryBot.create(
      :property,
      user:,
      sale_status: Property::SALE_STATUSES[:for_sale],
      address_line_1: "Maple House",
      town_city: "Guildford"
    )
  end

  let!(:for_rent_match) do
    FactoryBot.create(
      :property,
      :for_rent,
      user:,
      address_line_1: "Harbour Flat",
      town_city: "Sevenoaks"
    )
  end

  let!(:for_rent_other) do
    FactoryBot.create(
      :property,
      :for_rent,
      user:,
      address_line_1: "Other Rent",
      town_city: "Guildford"
    )
  end

  it "treats q as case-insensitive across all public catalogue pages" do
    get properties_path, params: {
      sale_status: Property::SALE_STATUSES[:for_sale],
      q: "hArBoUr"
    }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(for_sale_match.address_line_1)
    expect(response.body).not_to include(for_sale_other.address_line_1)
    expect(response.body).not_to include(for_rent_match.address_line_1) # sale_status filter excludes rentals

    get for_sale_index_path, params: { q: "hArBoUr" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(for_sale_match.address_line_1)
    expect(response.body).not_to include(for_rent_match.address_line_1)

    get for_rent_index_path, params: { q: "hArBoUr" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(for_rent_match.address_line_1)
    expect(response.body).not_to include(for_sale_match.address_line_1)

    get searches_path, params: {
      sale_status: Property::SALE_STATUSES[:for_sale],
      q: "hArBoUr"
    }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(for_sale_match.address_line_1)
    expect(response.body).not_to include(for_sale_other.address_line_1)
    expect(response.body).not_to include(for_rent_match.address_line_1)
  end

  it "treats town_city as case-insensitive across all public catalogue pages" do
    get properties_path, params: {
      sale_status: Property::SALE_STATUSES[:for_sale],
      town_city: "sEvEnOaKs"
    }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(for_sale_match.address_line_1)
    expect(response.body).not_to include(for_sale_other.address_line_1)

    get for_sale_index_path, params: { town_city: "sEvEnOaKs" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(for_sale_match.address_line_1)
    expect(response.body).not_to include(for_sale_other.address_line_1)

    get for_rent_index_path, params: { town_city: "sEvEnOaKs" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(for_rent_match.address_line_1)
    expect(response.body).not_to include(for_rent_other.address_line_1)

    get searches_path, params: {
      sale_status: Property::SALE_STATUSES[:for_sale],
      town_city: "sEvEnOaKs"
    }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(for_sale_match.address_line_1)
    expect(response.body).not_to include(for_sale_other.address_line_1)
  end

  it "applies the town alias on search pages and selects the canonical town in the form" do
    for_sale_match.update!(bedrooms: 2)
    for_rent_match.update!(bedrooms: 1)
    for_sale_other.update!(bedrooms: 2)

    get searches_path, params: { town: "Sevenoaks", min_bedrooms: 2 }

    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML.parse(response.body)
    expect(document.css('[data-testid="property-card"]').count).to eq(1)
    expect(response.body).to include(for_sale_match.address_line_1)
    expect(response.body).not_to include(for_rent_match.address_line_1)
    expect(response.body).not_to include(for_sale_other.address_line_1)

    town_select = document.at_css('[data-testid="property-filter-town-city"]')
    expect(town_select.at_css('option[selected][value="Sevenoaks"]')).to be_present
  end

  it "rejects unknown towns on public catalogue requests" do
    get searches_path, params: { town: "Atlantis", min_bedrooms: 2 }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to eq("Unknown town: Atlantis")
  end

  it "ignores price filters on dual sale and rental search pages until listing type is selected" do
    for_sale_match.update!(asking_price: 500_000)
    for_rent_match.update!(asking_price: 2_000)

    get searches_path, params: { min_price: "600,000" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(for_sale_match.address_line_1)
    expect(response.body).to include(for_rent_match.address_line_1)
    expect(response.body).not_to include(%(value="600,000"))

    get searches_path, params: {
      sale_status: Property::SALE_STATUSES[:for_sale],
      min_price: "600,000"
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(for_sale_match.address_line_1)
    expect(response.body).not_to include(for_rent_match.address_line_1)
    expect(response.body).to include(%(value="600,000"))
  end
end
