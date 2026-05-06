require "rails_helper"
require "nokogiri"

RSpec.describe "Admin users", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "users-admin@gotthekeys.com", password: "changeme123", password_confirmation: "changeme123") }

  before do
    sign_in admin
  end

  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  it "shows a seller search form on the index" do
    first_seller = FactoryBot.create(:user)
    second_seller = FactoryBot.create(:user)
    FactoryBot.create(:property, user: first_seller)
    FactoryBot.create(:property, :for_rent, user: first_seller)
    FactoryBot.create(:property, user: second_seller)

    get admin_sellers_path

    expect(response).to have_http_status(:ok)

    search_form = parsed_html.at_css('[data-testid="admin-users-search"]')
    expect(search_form).to be_present
    expect(search_form["action"]).to eq(admin_sellers_path)

    search_input = search_form.at_css('[data-testid="admin-users-search-input"]')
    expect(search_input).to be_present
    expect(search_input["placeholder"]).to eq("Name, email, or mobile")

    clear_link = search_form.at_css('[data-testid="admin-users-search-clear"]')
    expect(clear_link).to be_present
    expect(clear_link["href"]).to eq(admin_sellers_path)

    count_label = parsed_html.at_css('[data-testid="admin-users-count"]')
    expect(count_label).to be_present
    expect(count_label.text.strip).to eq("2 sellers total")

    sale_badge = parsed_html.at_css(%([data-testid="admin-user-sale-count-#{first_seller.id}"]))
    rent_badge = parsed_html.at_css(%([data-testid="admin-user-rent-count-#{first_seller.id}"]))
    seller_row = parsed_html.at_css(%([data-testid="admin-user-row-#{first_seller.id}"]))

    expect(sale_badge).to be_present
    expect(sale_badge.text.strip).to eq("1 For Sale")
    expect(rent_badge).to be_present
    expect(rent_badge.text.strip).to eq("1 For Rent")
    expect(seller_row.text).to include(first_seller.email)
    expect(seller_row.text).not_to include("2 properties")
  end

  it "filters sellers by full name" do
    matching_user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    non_matching_user = FactoryBot.create(:user, first_name: "Morgan", last_name: "Lake", email: "morgan@example.com")
    FactoryBot.create(:property, user: matching_user)
    FactoryBot.create(:property, user: non_matching_user)

    get admin_sellers_path, params: { q: "Taylor Stone" }

    expect(response).to have_http_status(:ok)

    row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to include("admin-user-row-#{matching_user.id}")
    expect(row_ids).not_to include("admin-user-row-#{non_matching_user.id}")

    search_input = parsed_html.at_css('[data-testid="admin-users-search-input"]')
    expect(search_input["value"]).to eq("Taylor Stone")
  end

  it "treats q as case-insensitive" do
    matching_user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    non_matching_user = FactoryBot.create(:user, first_name: "Morgan", last_name: "Lake", email: "morgan@example.com")
    FactoryBot.create(:property, user: matching_user)
    FactoryBot.create(:property, user: non_matching_user)

    get admin_sellers_path, params: { q: "tAYlOr sToNe" }

    expect(response).to have_http_status(:ok)

    row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to include("admin-user-row-#{matching_user.id}")
    expect(row_ids).not_to include("admin-user-row-#{non_matching_user.id}")
  end

  it "filters sellers by email and shows an empty state when there are no matches" do
    taylor = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    matching_user = FactoryBot.create(:user, first_name: "Casey", last_name: "Blue", email: "casey.blue@example.com")
    FactoryBot.create(:property, user: taylor)
    FactoryBot.create(:property, user: matching_user)

    get admin_sellers_path, params: { q: "casey.blue@" }

    expect(response).to have_http_status(:ok)

    row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to eq(["admin-user-row-#{matching_user.id}"])

    get admin_sellers_path, params: { q: "nobody here" }

    expect(response).to have_http_status(:ok)

    empty_copy = parsed_html.at_css(".empty-copy")
    expect(empty_copy).to be_present
    expect(empty_copy.text.strip).to eq("No sellers match this search.")
  end

  it "paginates sellers with the same page size as the customers index" do
    created_users = 26.times.map do |index|
      user = FactoryBot.create(
        :user,
        first_name: "Seller",
        last_name: format("User %02d", index),
        email: "seller-#{index}@example.com"
      )
      FactoryBot.create(:property, user: user)
      user
    end

    get admin_sellers_path

    expect(response).to have_http_status(:ok)

    page_one_row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(page_one_row_ids.length).to eq(25)
    expect(page_one_row_ids).to include("admin-user-row-#{created_users.first.id}")
    expect(page_one_row_ids).not_to include("admin-user-row-#{created_users.last.id}")
    expect(parsed_html.at_css(".pagination")).to be_present

    get admin_sellers_path, params: { page: 2 }

    expect(response).to have_http_status(:ok)

    page_two_row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(page_two_row_ids).to eq(["admin-user-row-#{created_users.last.id}"])
  end

  it "shows separate for-sale and for-rent badges on the sellers index" do
    user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    3.times { FactoryBot.create(:property, user: user) }
    2.times { FactoryBot.create(:property, :for_rent, user: user) }

    get admin_sellers_path

    expect(response).to have_http_status(:ok)

    sale_badge = parsed_html.at_css(%([data-testid="admin-user-sale-count-#{user.id}"]))
    rent_badge = parsed_html.at_css(%([data-testid="admin-user-rent-count-#{user.id}"]))

    expect(sale_badge).to be_present
    expect(sale_badge.text.strip).to eq("3 For Sale")
    expect(sale_badge["class"]).to include("badge--accent")

    expect(rent_badge).to be_present
    expect(rent_badge.text.strip).to eq("2 For Rent")
    expect(rent_badge["class"]).to include("badge--success")
  end

  it "lists all of the seller's properties with their current statuses on the profile page" do
    user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    published_property = FactoryBot.create(:property, user: user, address_line_1: "Cedar View", listing_state: "published")
    draft_property = FactoryBot.create(:property, :draft, :for_rent, user: user, address_line_1: "Maple House")
    other_user_property = FactoryBot.create(:property, address_line_1: "Someone Else's Home")
    FactoryBot.create(:photo, property: published_property, primary: true, image_filename: "properties/admin-user-property-thumb.webp")

    get admin_seller_path(user)

    expect(response).to have_http_status(:ok)

    row_ids = parsed_html.css('[data-testid^="admin-user-property-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to include("admin-user-property-row-#{published_property.id}")
    expect(row_ids).to include("admin-user-property-row-#{draft_property.id}")
    expect(row_ids).not_to include("admin-user-property-row-#{other_user_property.id}")

    expect(response.body).to include("Listings and status")
    expect(response.body).to include("Cedar View")
    expect(response.body).to include("Maple House")
    expect(response.body).not_to include("Someone Else's Home")
    expect(response.body).to include(I18n.t("ui.properties.listing_states.published"))
    expect(response.body).to include(I18n.t("ui.properties.listing_states.draft"))

    sale_badge = parsed_html.at_css(%([data-testid="admin-user-property-sale-status-badge-#{published_property.id}"]))
    rent_badge = parsed_html.at_css(%([data-testid="admin-user-property-sale-status-badge-#{draft_property.id}"]))
    listing_thumbnail = parsed_html.at_css(%([data-testid="admin-user-property-row-#{published_property.id}"] img.admin-asset-item__thumbnail))

    expect(sale_badge).to be_present
    expect(sale_badge.text.strip).to eq("For Sale")
    expect(sale_badge["class"]).to include("badge--accent")

    expect(rent_badge).to be_present
    expect(rent_badge.text.strip).to eq("For Rent")
    expect(rent_badge["class"]).to include("badge--success")
    expect(listing_thumbnail).to be_present
    expect(listing_thumbnail["src"]).to include("admin-user-property-thumb.webp")
  end

  it "lists all of the seller's saved properties on the profile page" do
    user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    FactoryBot.create(:property, user: user, address_line_1: "Owned Home")
    saved_sale_property = FactoryBot.create(:property, address_line_1: "Saved Sale Home", listing_state: "published")
    saved_rent_property = FactoryBot.create(:property, :for_rent, :draft, address_line_1: "Saved Rental Home")
    unsaved_property = FactoryBot.create(:property, address_line_1: "Not Saved Home")
    FactoryBot.create(:photo, property: saved_sale_property, primary: true, image_filename: "properties/admin-user-saved-property-thumb.webp")

    FactoryBot.create(:saved_property, user: user, property: saved_sale_property)
    FactoryBot.create(:saved_property, user: user, property: saved_rent_property)

    get admin_seller_path(user)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Saved properties")
    expect(response.body).to include("Saved Sale Home")
    expect(response.body).to include("Saved Rental Home")
    expect(response.body).not_to include("Not Saved Home")

    row_ids = parsed_html.css('[data-testid^="admin-user-saved-property-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to include("admin-user-saved-property-row-#{saved_sale_property.id}")
    expect(row_ids).to include("admin-user-saved-property-row-#{saved_rent_property.id}")
    expect(row_ids).not_to include("admin-user-saved-property-row-#{unsaved_property.id}")

    sale_badge = parsed_html.at_css(%([data-testid="admin-user-saved-property-sale-status-badge-#{saved_sale_property.id}"]))
    rent_badge = parsed_html.at_css(%([data-testid="admin-user-saved-property-sale-status-badge-#{saved_rent_property.id}"]))
    saved_thumbnail = parsed_html.at_css(%([data-testid="admin-user-saved-property-row-#{saved_sale_property.id}"] img.admin-asset-item__thumbnail))

    expect(sale_badge).to be_present
    expect(sale_badge.text.strip).to eq("For Sale")
    expect(rent_badge).to be_present
    expect(rent_badge.text.strip).to eq("For Rent")
    expect(saved_thumbnail).to be_present
    expect(saved_thumbnail["src"]).to include("admin-user-saved-property-thumb.webp")
  end

  it "shows property thumbnails in the recent booking activity list" do
    user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    property = FactoryBot.create(:property, user: user, address_line_1: "Cedar View")
    slot = next_booking_slot(hour: 11)
    appointment = FactoryBot.create(:appointment, property:, customer_name: "Alex Viewer", requested_time: slot, scheduled_at: slot)
    FactoryBot.create(:photo, property: property, primary: true, image_filename: "properties/admin-user-booking-thumb.webp")

    get admin_seller_path(user)

    expect(response).to have_http_status(:ok)

    booking_thumbnail = parsed_html.at_css(".admin-list__item img.admin-asset-item__thumbnail")
    expect(response.body).to include(appointment.public_reference)
    expect(booking_thumbnail).to be_present
    expect(booking_thumbnail["src"]).to include("admin-user-booking-thumb.webp")
  end

  it "lists all of the seller's saved searches on the profile page" do
    user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    FactoryBot.create(:property, user: user, address_line_1: "Owned Home")
    FactoryBot.create(:property, :for_rent, town_city: "Berlin", bedrooms: 2, address_line_1: "Riverside Court", property_description: "Bright Riverside apartment")
    matching_search = SavedSearch.create!(
      user: user,
      email: user.email,
      locale: "de",
      alerts_enabled: true,
      search_query: "Riverside",
      sale_status: "For Rent",
      town_city: "Berlin",
      min_bedrooms: 2
    )
    second_search = SavedSearch.create!(
      user: user,
      email: user.email,
      locale: "en",
      alerts_enabled: false,
      sale_status: "For Sale",
      max_price: 750000
    )

    get admin_seller_path(user)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Saved searches")
    expect(response.body).to include("Riverside")
    expect(response.body).to include("Berlin")
    expect(response.body).to include("2+ bedrooms")
    expect(response.body).to include("For Rent")
    expect(response.body).to include("Up to")
    expect(response.body).to include("Deutsch")
    expect(response.body).to include("Alerts on")
    expect(response.body).to include("Alerts off")

    row_ids = parsed_html.css('[data-testid^="admin-user-saved-search-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to include("admin-user-saved-search-row-#{matching_search.id}")
    expect(row_ids).to include("admin-user-saved-search-row-#{second_search.id}")

    matches_link = parsed_html.at_css(%([data-testid="admin-user-saved-search-matches-#{matching_search.id}"]))
    expect(matches_link).to be_present
    expect(matches_link["href"]).to eq(admin_properties_path(q: "Riverside", sale_status: "For Rent", town_city: "Berlin", min_bedrooms: "2"))
    expect(matches_link.text).to include("View")
  end

  it "excludes registered users who do not own any properties" do
    seller = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    nonseller = FactoryBot.create(:user, first_name: "Alex", last_name: "Cole", email: "alex.cole@example.com")
    FactoryBot.create(:property, user: seller)

    get admin_sellers_path

    expect(response).to have_http_status(:ok)

    row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to include("admin-user-row-#{seller.id}")
    expect(row_ids).not_to include("admin-user-row-#{nonseller.id}")
    expect(response.body).not_to include("alex.cole@example.com")
  end
end
