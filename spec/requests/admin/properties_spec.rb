require "rails_helper"

RSpec.describe "Admin properties", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "property-admin@gotthekeys.com", password: "secret123", password_confirmation: "secret123") }
  let(:property) { FactoryBot.create(:property, :review_pending) }

  before do
    sign_in admin
  end

  it "shows listing readiness and asset inventory on the admin detail page" do
    FactoryBot.create(:photo, property:, primary: true, image_filename: "admin-shot.jpg")
    FactoryBot.create(:floor_plan, property:, label: "Ground floor")
    FactoryBot.create(:property_document, property:, title: "Admin brochure", file_name: "admin-brochure.pdf")
    AuditLogger.log!(auditable: property, property:, admin:, action: "listing_state_changed", message: "Listing moved to review pending.")

    get admin_property_path(property)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Listing readiness")
    expect(response.body).to include("admin-shot.jpg")
    expect(response.body).to include("Ground floor")
    expect(response.body).to include("Admin brochure")
    expect(response.body).to include(%(data-testid="admin-property-activity-timeline"))
    expect(response.body).to include(%(data-testid="listing-transition-published"))
    expect(response.body).to include(%(data-testid="listing-transition-grid"))
    expect(response.body).to include("admin-property-page__actions")
    expect(response.body).to include("admin-property-readiness__transition-form")
    expect(response.body).to include("admin-property-readiness__transition-button")
  end

  it "lets admins move a listing through moderation states" do
    patch transition_admin_property_path(property), params: { listing_state: "published" }

    expect(response).to redirect_to(admin_property_path(property))
    expect(property.reload.listing_state).to eq("published")
    expect(property.audit_logs.recent_first.first.action).to eq("listing_state_changed")
  end
end
