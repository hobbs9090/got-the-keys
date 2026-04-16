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

  it "keeps the index working when a property has no seller record" do
    orphaned_property = FactoryBot.create(:property, address_line_1: "Orphaned House")
    orphaned_property.update_column(:user_id, nil)

    get admin_properties_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Orphaned House")
    expect(response.body).to include("Missing seller record")
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

  it "shows a fallback seller label on the admin detail page when the seller record is missing" do
    orphaned_property = FactoryBot.create(:property, :review_pending, address_line_1: "Detached Support Case")
    orphaned_property.update_column(:user_id, nil)

    get admin_property_path(orphaned_property)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Detached Support Case")
    expect(response.body).to include("Missing seller record")
  end

  it "lets admins move a listing through moderation states" do
    patch transition_admin_property_path(property), params: { listing_state: "published" }

    expect(response).to redirect_to(admin_property_path(property))
    expect(property.reload.listing_state).to eq("published")
    expect(property.audit_logs.recent_first.first.action).to eq("listing_state_changed")
  end
end
