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

    get admin_property_path(property)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Listing readiness")
    expect(response.body).to include("admin-shot.jpg")
    expect(response.body).to include("Ground floor")
    expect(response.body).to include(%(data-testid="listing-transition-published"))
  end

  it "lets admins move a listing through moderation states" do
    patch transition_admin_property_path(property), params: { listing_state: "published" }

    expect(response).to redirect_to(admin_property_path(property))
    expect(property.reload.listing_state).to eq("published")
  end
end
