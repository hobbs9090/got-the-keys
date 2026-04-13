require "rails_helper"

RSpec.describe "Property catalogue", type: :system do
  def create_property(user:, sale_status:, address_line_1:, bedrooms: 2, **attrs)
    FactoryBot.create(:property, user:, address_line_1:, bedrooms:, sale_status:, **attrs)
  end

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "changeme"
    click_button "Sign in"
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

  it "shows save filter on the for-rent catalogue for a signed-in user" do
    user = FactoryBot.create(:user, email: "renter-filters@example.com", password: "changeme", password_confirmation: "changeme")

    sign_in_as(user)
    visit for_rent_index_path

    expect(page).to have_css('[data-testid="save-property-filters"]')
  end

  it "links save filter to sign-in for guests on the for-rent catalogue" do
    visit for_rent_index_path(town_city: "Sevenoaks")

    link = page.find('[data-testid="save-property-filters-sign-in"]')
    expect(link[:href]).to include(CGI.escape(for_rent_index_path(town_city: "Sevenoaks")))
  end

  it "lets a signed-in visitor save filters from the for-rent catalogue via the filter form", js: true do
    owner = FactoryBot.create(:user)
    renter = FactoryBot.create(:user, email: "renter-save-filter@example.com", password: "changeme", password_confirmation: "changeme")
    create_property(user: owner, sale_status: Property::SALE_STATUSES[:for_rent], address_line_1: "Riverside View", town_city: "Sevenoaks")

    sign_in_as(renter)
    visit for_rent_index_path

    fill_in "q", with: "Riverside"

    find('[data-testid="save-property-filters"]').click

    expect(page).to have_text("Saved search created")
    expect(SavedSearch.last.search_query).to eq("Riverside")
    expect(SavedSearch.last.sale_status).to eq(Property::SALE_STATUSES[:for_rent])
  end

  it "shows the saved searches band with an empty state when signed in and none are saved yet" do
    user = FactoryBot.create(:user, email: "empty-searches@example.com", password: "changeme", password_confirmation: "changeme")

    sign_in_as(user)

    visit properties_path(town_city: "Westerham")

    expect(page).to have_css('[data-testid="catalogue-saved-searches"]')
    expect(page).to have_css('[data-testid="catalogue-saved-searches-empty"]')
    expect(page).to have_no_css('[data-testid="saved-search-card"]')
  end

  it "lets a signed-in visitor save the current search and lists it on the catalogue" do
    owner = FactoryBot.create(:user)
    buyer = FactoryBot.create(:user, email: "buyer@example.com", password: "changeme", password_confirmation: "changeme")
    create_property(user: owner, sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "The Mead", bedrooms: 4)

    sign_in_as(buyer)

    visit properties_path(town_city: "Westerham", min_bedrooms: 3)

    within('[data-testid="saved-search-panel"]') do
      click_button "Save search"
    end

    expect(page).to have_text("Saved search created for")
    expect(SavedSearch.last.user).to eq(buyer)
    expect(SavedSearch.last.email).to eq("buyer@example.com")

    expect(page).to have_css('[data-testid="catalogue-saved-searches"]')
    expect(page).to have_css('[data-testid="saved-search-card"]', count: 1)
  end
end
