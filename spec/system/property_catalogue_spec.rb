require "rails_helper"

RSpec.describe "Property catalogue", type: :system do
  def create_property(user:, sale_status:, address_line_1:, bedrooms: 2)
    FactoryBot.create(:property, user:, address_line_1:, bedrooms:, sale_status:)
  end

  it "shows sale and rent listings in their respective catalogues" do
    user = FactoryBot.create(:user)
    create_property(user:, sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "Little Orchard")
    create_property(user:, sale_status: Property::SALE_STATUSES[:for_rent], address_line_1: "14 Bazley Road")

    visit for_sale_index_path
    expect(page).to have_text("Little Orchard")

    visit for_rent_index_path
    expect(page).to have_text("14 Bazley Road")
  end

  it "shows the correct sale status on property detail pages" do
    user = FactoryBot.create(:user)
    sale_property = create_property(user:, sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "Little Orchard")
    rent_property = create_property(user:, sale_status: Property::SALE_STATUSES[:for_rent], address_line_1: "Harbour Cottage")

    visit property_path(sale_property)
    expect(page).to have_text("Little Orchard")
    expect(page).to have_text("For Sale")

    visit property_path(rent_property)
    expect(page).to have_text("Harbour Cottage")
    expect(page).to have_text("For Rent")
  end

  it "renders the right bedroom labels on property detail pages" do
    user = FactoryBot.create(:user)
    studio = create_property(user:, sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "Studio Lane", bedrooms: 0)
    one_bed = create_property(user:, sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "One Bed Row", bedrooms: 1)
    two_bed = create_property(user:, sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "Two Bed View", bedrooms: 2)

    visit property_path(studio)
    expect(page).to have_text("Studio Flat")

    visit property_path(one_bed)
    expect(page).to have_text("1 bedroom")

    visit property_path(two_bed)
    expect(page).to have_text("2 bedrooms")
  end

  it "lets visitors save the current search" do
    user = FactoryBot.create(:user)
    create_property(user:, sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "The Mead", bedrooms: 4)

    visit properties_path(town_city: "Westerham", min_bedrooms: 3)

    within('[data-testid="saved-search-panel"]') do
      fill_in "saved_search_email", with: "buyer@example.com"
      click_button "Save search"
    end

    expect(page).to have_text("Saved search created for")
    expect(SavedSearch.last.email).to eq("buyer@example.com")
  end
end
