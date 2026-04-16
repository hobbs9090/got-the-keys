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
end

