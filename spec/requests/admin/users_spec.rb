require "rails_helper"
require "nokogiri"

RSpec.describe "Admin users", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "users-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  it "shows a seller search form on the index" do
    FactoryBot.create_list(:user, 2)

    get admin_users_path

    expect(response).to have_http_status(:ok)

    search_form = parsed_html.at_css('[data-testid="admin-users-search"]')
    expect(search_form).to be_present
    expect(search_form["action"]).to eq(admin_users_path)

    search_input = search_form.at_css('[data-testid="admin-users-search-input"]')
    expect(search_input).to be_present
    expect(search_input["placeholder"]).to eq("Name, email, or mobile")

    clear_link = search_form.at_css('[data-testid="admin-users-search-clear"]')
    expect(clear_link).to be_present
    expect(clear_link["href"]).to eq(admin_users_path)

    count_label = parsed_html.at_css('[data-testid="admin-users-count"]')
    expect(count_label).to be_present
    expect(count_label.text.strip).to eq("2 sellers total")
  end

  it "filters sellers by full name" do
    matching_user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    non_matching_user = FactoryBot.create(:user, first_name: "Morgan", last_name: "Lake", email: "morgan@example.com")

    get admin_users_path, params: { q: "Taylor Stone" }

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

    get admin_users_path, params: { q: "tAYlOr sToNe" }

    expect(response).to have_http_status(:ok)

    row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to include("admin-user-row-#{matching_user.id}")
    expect(row_ids).not_to include("admin-user-row-#{non_matching_user.id}")
  end

  it "filters sellers by email and shows an empty state when there are no matches" do
    FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    matching_user = FactoryBot.create(:user, first_name: "Casey", last_name: "Blue", email: "casey.blue@example.com")

    get admin_users_path, params: { q: "casey.blue@" }

    expect(response).to have_http_status(:ok)

    row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to eq(["admin-user-row-#{matching_user.id}"])

    get admin_users_path, params: { q: "nobody here" }

    expect(response).to have_http_status(:ok)

    empty_copy = parsed_html.at_css(".empty-copy")
    expect(empty_copy).to be_present
    expect(empty_copy.text.strip).to eq("No sellers match this search.")
  end

  it "paginates sellers with the same page size as the customers index" do
    created_users = 26.times.map do |index|
      FactoryBot.create(
        :user,
        first_name: "Seller",
        last_name: format("User %02d", index),
        email: "seller-#{index}@example.com"
      )
    end

    get admin_users_path

    expect(response).to have_http_status(:ok)

    page_one_row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(page_one_row_ids.length).to eq(25)
    expect(page_one_row_ids).to include("admin-user-row-#{created_users.first.id}")
    expect(page_one_row_ids).not_to include("admin-user-row-#{created_users.last.id}")
    expect(parsed_html.at_css(".pagination")).to be_present

    get admin_users_path, params: { page: 2 }

    expect(response).to have_http_status(:ok)

    page_two_row_ids = parsed_html.css('[data-testid^="admin-user-row-"]').map { |row| row["data-testid"] }
    expect(page_two_row_ids).to eq(["admin-user-row-#{created_users.last.id}"])
  end

  it "lists all of the seller's properties with their current statuses on the profile page" do
    user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    published_property = FactoryBot.create(:property, user:, address_line_1: "Cedar View", listing_state: "published")
    draft_property = FactoryBot.create(:property, :draft, user:, address_line_1: "Maple House")
    other_user_property = FactoryBot.create(:property, address_line_1: "Someone Else's Home")

    get admin_user_path(user)

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
  end
end
