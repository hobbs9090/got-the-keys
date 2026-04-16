require "rails_helper"
require "nokogiri"

RSpec.describe "Admin properties", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "property-admin@gotthekeys.com", password: "secret123", password_confirmation: "secret123") }
  let(:property) { FactoryBot.create(:property, :review_pending) }

  before do
    sign_in admin
  end

  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  it "shows a property search form on the index" do
    get admin_properties_path

    expect(response).to have_http_status(:ok)

    search_form = parsed_html.at_css('[data-testid="admin-properties-search"]')
    expect(search_form).to be_present
    expect(search_form["action"]).to eq(admin_properties_path)

    search_input = search_form.at_css('[data-testid="admin-properties-search-input"]')
    expect(search_input).to be_present
    expect(search_input["placeholder"]).to eq("Address, postcode, seller, or status")

    status_select = search_form.at_css('[data-testid="admin-properties-status-select"]')
    expect(status_select).to be_present
    expect(status_select.at_css('option[value=""]')&.text).to eq("All statuses")
    expect(status_select.css("option").map { |option| option["value"] }).to include(*Property::LISTING_STATES)

    clear_link = search_form.at_css('[data-testid="admin-properties-search-clear"]')
    expect(clear_link).to be_present
    expect(clear_link["href"]).to eq(admin_properties_path)
  end

  it "filters properties by address and seller details" do
    matching_user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")
    matching_property = FactoryBot.create(:property, user: matching_user, address_line_1: "Cedar View")
    non_matching_property = FactoryBot.create(:property, address_line_1: "Maple House")

    get admin_properties_path, params: { q: "Taylor Cedar" }

    expect(response).to have_http_status(:ok)

    card_ids = parsed_html.css('[data-testid^="admin-property-card-"]').map { |row| row["data-testid"] }
    expect(card_ids).to include("admin-property-card-#{matching_property.id}")
    expect(card_ids).not_to include("admin-property-card-#{non_matching_property.id}")

    search_input = parsed_html.at_css('[data-testid="admin-properties-search-input"]')
    expect(search_input["value"]).to eq("Taylor Cedar")
  end

  it "shows an empty state when no properties match the search" do
    FactoryBot.create(:property, address_line_1: "Willow Lodge")

    get admin_properties_path, params: { q: "nothing here" }

    expect(response).to have_http_status(:ok)

    empty_copy = parsed_html.at_css(".empty-copy")
    expect(empty_copy).to be_present
    expect(empty_copy.text.strip).to eq("No properties match this search.")
  end

  it "filters properties by listing status" do
    review_property = FactoryBot.create(:property, :review_pending, address_line_1: "Review Queue House")
    published_property = FactoryBot.create(:property, listing_state: "published", address_line_1: "Published Lane")

    get admin_properties_path, params: { listing_state: "review_pending" }

    card_ids = parsed_html.css('[data-testid^="admin-property-card-"]').map { |row| row["data-testid"] }
    expect(card_ids).to include("admin-property-card-#{review_property.id}")
    expect(card_ids).not_to include("admin-property-card-#{published_property.id}")

    status_select = parsed_html.at_css('[data-testid="admin-properties-status-select"]')
    expect(status_select.at_css('option[selected][value="review_pending"]')).to be_present
  end

  it "shows saved filters at the top of the admin properties page" do
    owner_user = FactoryBot.create(:user, email: admin.email)
    saved_search = FactoryBot.create(:saved_search, user: owner_user, town_city: "Sevenoaks", min_bedrooms: 3, alerts_enabled: true)
    stale_search = FactoryBot.create(:saved_search, user: owner_user, town_city: "Old Town", alerts_enabled: true)
    stale_search.update_column(:created_at, 6.months.ago)
    disabled_search = FactoryBot.create(:saved_search, user: owner_user, town_city: "Disabled Town", alerts_enabled: false)
    other_user_search = FactoryBot.create(:saved_search, town_city: "Other User Town", alerts_enabled: true)

    get admin_properties_path

    expect(response).to have_http_status(:ok)

    panel = parsed_html.at_css('[data-testid="admin-saved-filters-panel"]')
    expect(panel).to be_present
    expect(parsed_html.css('[data-testid="admin-saved-filter-card"]').count).to eq(1)

    apply_link = parsed_html.at_css(%([data-testid="admin-apply-saved-filter-#{saved_search.id}"]))
    expect(apply_link).to be_present
    expect(apply_link["href"]).to include("town_city=Sevenoaks")
    expect(apply_link["href"]).to include("min_bedrooms=3")
    remove_button = parsed_html.at_css(%(form button[data-testid="admin-remove-saved-filter-#{saved_search.id}"]))
    expect(remove_button).to be_present
    expect(parsed_html.at_css(%([data-testid="admin-apply-saved-filter-#{stale_search.id}"]))).not_to be_present
    expect(parsed_html.at_css(%([data-testid="admin-apply-saved-filter-#{disabled_search.id}"]))).not_to be_present
    expect(parsed_html.at_css(%([data-testid="admin-apply-saved-filter-#{other_user_search.id}"]))).not_to be_present
  end

  it "applies saved filter params on the admin properties index" do
    FactoryBot.create(
      :property,
      address_line_1: "Filter Match House",
      town_city: "Sevenoaks",
      bedrooms: 4,
      asking_price: 650_000,
      sale_status: Property::SALE_STATUSES[:for_sale]
    )
    FactoryBot.create(
      :property,
      address_line_1: "Filtered Out Rental",
      town_city: "Sevenoaks",
      bedrooms: 4,
      asking_price: 2_100,
      sale_status: Property::SALE_STATUSES[:for_rent]
    )

    get admin_properties_path, params: {
      sale_status: Property::SALE_STATUSES[:for_sale],
      town_city: "Sevenoaks",
      min_bedrooms: 4,
      min_price: 600_000
    }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Filter Match House")
    expect(response.body).not_to include("Filtered Out Rental")
  end

  it "shows listing readiness and asset inventory on the admin detail page" do
    FactoryBot.create(:photo, property:, primary: true, image_filename: "admin-shot.jpg")
    FactoryBot.create(:floor_plan, property:, label: "Ground floor")
    document = FactoryBot.create(:property_document, property:, title: "Admin brochure", file_name: "admin-brochure.pdf")
    AuditLogger.log!(auditable: property, property:, admin:, action: "listing_state_changed", message: "Listing moved to review pending.")

    get admin_property_path(property)

    page = Nokogiri::HTML(response.body)
    download_link = page.at_css(%(a[href="#{download_property_property_document_path(property, document)}"]))

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Listing readiness")
    expect(response.body).to include(%(data-testid="admin-property-photo-thumbnail-))
    expect(response.body).to include("Ground floor")
    expect(response.body).to include("Admin brochure")
    expect(response.body).to include(%(data-testid="admin-property-activity-timeline"))
    expect(response.body).to include(%(data-testid="listing-transition-published"))
    expect(response.body).to include(%(data-testid="listing-transition-grid"))
    expect(response.body).to include("admin-property-page__actions")
    expect(response.body).to include("admin-property-readiness__transition-form")
    expect(response.body).to include("admin-property-readiness__transition-button")
    expect(download_link).to be_present
    expect(download_link["data-turbo"]).to eq("false")
    expect(download_link["download"]).to eq("admin-brochure.pdf")
  end

  it "lets admins move a listing through moderation states" do
    patch transition_admin_property_path(property), params: { listing_state: "published" }

    expect(response).to redirect_to(admin_property_path(property))
    expect(property.reload.listing_state).to eq("published")
    expect(property.audit_logs.recent_first.first.action).to eq("listing_state_changed")
  end
end
