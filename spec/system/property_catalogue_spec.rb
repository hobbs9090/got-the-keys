require "rails_helper"

RSpec.describe "Property catalogue", type: :system do
  def create_property(user:, sale_status:, address_line_1:, bedrooms: 2, **attrs)
    FactoryBot.create(:property, user:, address_line_1:, bedrooms:, sale_status:, **attrs)
  end

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "changeme123"
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
    user = FactoryBot.create(:user, email: "renter-filters@example.com", password: "changeme123", password_confirmation: "changeme123")

    sign_in_as(user)
    visit for_rent_index_path

    expect(page).to have_css('[data-testid="save-property-filters"]')
  end

  it "shows save filter on the for-sale catalogue for a signed-in user" do
    user = FactoryBot.create(:user, email: "buyer-filters@example.com", password: "changeme123", password_confirmation: "changeme123")

    sign_in_as(user)
    visit for_sale_index_path

    expect(page).to have_css('[data-testid="save-property-filters"]')
  end

  it "shows save filter on the search page for a signed-in user" do
    user = FactoryBot.create(:user, email: "search-filters@example.com", password: "changeme123", password_confirmation: "changeme123")

    sign_in_as(user)
    visit searches_path

    expect(page).to have_css('[data-testid="save-property-filters"]')
  end

  it "links save filter to sign-in for guests on the for-rent catalogue" do
    create_property(user: FactoryBot.create(:user), sale_status: Property::SALE_STATUSES[:for_rent], address_line_1: "Rent Save Link", town_city: "Sevenoaks")

    visit for_rent_index_path(town_city: "Sevenoaks")

    link = page.find('[data-testid="save-property-filters-sign-in"]')
    expect(link[:href]).to include(CGI.escape(for_rent_index_path(town_city: "Sevenoaks")))
  end

  it "links save filter to sign-in for guests on the for-sale catalogue" do
    create_property(user: FactoryBot.create(:user), sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "Sale Save Link", town_city: "Guildford")

    visit for_sale_index_path(town_city: "Guildford")

    link = page.find('[data-testid="save-property-filters-sign-in"]')
    expect(link[:href]).to include(CGI.escape(for_sale_index_path(town_city: "Guildford")))
  end

  it "links save filter to sign-in for guests on the search page" do
    create_property(user: FactoryBot.create(:user), sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "Search Save Link", town_city: "Sevenoaks")

    visit searches_path(town_city: "Sevenoaks")

    link = page.find('[data-testid="save-property-filters-sign-in"]')
    expect(link[:href]).to include(CGI.escape(searches_path(town_city: "Sevenoaks")))
  end

  it "lets a signed-in visitor save filters from the for-rent catalogue via the filter form", js: true do
    owner = FactoryBot.create(:user)
    renter = FactoryBot.create(:user, email: "renter-save-filter@example.com", password: "changeme123", password_confirmation: "changeme123")
    create_property(
      user: owner,
      sale_status: Property::SALE_STATUSES[:for_rent],
      address_line_1: "Riverside View",
      town_city: "Sevenoaks",
      asking_price: 2_200
    )

    sign_in_as(renter)
    visit for_rent_index_path

    fill_in "q", with: "Riverside"

    find('[data-testid="save-property-filters"]').click

    expect(page).to have_text("Saved search created")
    expect(SavedSearch.last.search_query).to eq("Riverside")
    expect(SavedSearch.last.sale_status).to eq(Property::SALE_STATUSES[:for_rent])
  end

  it "lets a signed-in visitor save filters from the search page and returns to search results", js: true do
    owner = FactoryBot.create(:user)
    searcher = FactoryBot.create(:user, email: "search-save-filter@example.com", password: "changeme123", password_confirmation: "changeme123")
    create_property(
      user: owner,
      sale_status: Property::SALE_STATUSES[:for_sale],
      address_line_1: "Hillcrest Terrace",
      town_city: "Reigate",
      asking_price: 550_000
    )

    sign_in_as(searcher)
    visit searches_path

    fill_in "q", with: "Hillcrest"

    find('[data-testid="save-property-filters"]').click

    expect(page).to have_text("Saved search created")
    expect(page).to have_current_path(searches_path, ignore_query: true)
    expect(SavedSearch.last.search_query).to eq("Hillcrest")
  end

  it "lets a signed-in visitor save a town alias filter from the search page", js: true do
    owner = FactoryBot.create(:user)
    searcher = FactoryBot.create(:user, email: "search-town-save-filter@example.com", password: "changeme123", password_confirmation: "changeme123")
    create_property(
      user: owner,
      sale_status: Property::SALE_STATUSES[:for_sale],
      address_line_1: "Knole View",
      town_city: "Sevenoaks",
      bedrooms: 2
    )
    create_property(
      user: owner,
      sale_status: Property::SALE_STATUSES[:for_sale],
      address_line_1: "Other View",
      town_city: "Guildford",
      bedrooms: 2
    )

    sign_in_as(searcher)
    visit searches_path(town: "Sevenoaks", min_bedrooms: 2)

    expect(page).to have_css('[data-testid="property-card"]', count: 1)
    expect(page).to have_select("town_city", selected: "Sevenoaks")

    find('[data-testid="save-property-filters"]').click

    expect(page).to have_text("Saved search created")
    expect(SavedSearch.last.town_city).to eq("Sevenoaks")
    expect(SavedSearch.last.min_bedrooms).to eq(2)
  end

  it "shows the saved searches band with an empty state when signed in and none are saved yet" do
    user = FactoryBot.create(:user, email: "empty-searches@example.com", password: "changeme123", password_confirmation: "changeme123")
    create_property(user: FactoryBot.create(:user), sale_status: Property::SALE_STATUSES[:for_sale], address_line_1: "Empty State Link", town_city: "Westerham")

    sign_in_as(user)

    visit properties_path(town_city: "Westerham")

    expect(page).to have_css('[data-testid="catalogue-saved-searches"]')
    expect(page).to have_css('[data-testid="catalogue-saved-searches-empty"]')
    expect(page).to have_no_css('[data-testid="saved-search-card"]')
  end

  it "lets a signed-in visitor save the current search and lists it on the catalogue" do
    owner = FactoryBot.create(:user)
    buyer = FactoryBot.create(:user, email: "buyer@example.com", password: "changeme123", password_confirmation: "changeme123")
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
