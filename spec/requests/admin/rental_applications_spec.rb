require "rails_helper"

RSpec.describe "Admin rental applications", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "lettings-admin@gotthekeys.com", password: "secret123", password_confirmation: "secret123") }
  let(:application) { FactoryBot.create(:rental_application) }

  before do
    sign_in admin
  end

  it "renders the rental applications board" do
    application

    get admin_rentals_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Rental applications board")
    expect(response.body).to include(%(data-testid="rental-applications-column-received"))
  end

  it "updates a rental application and syncs progression" do
    patch admin_rental_path(application), params: {
      rental_application: {
        status: "approved",
        guarantor_required: "0",
        guarantor_available: "0",
        affordability_notes: "Checks complete and approved.",
        internal_notes: "Approved subject to move-in coordination."
      }
    }

    expect(response).to redirect_to(admin_rental_path(application))
    expect(application.reload.status).to eq("approved")
    expect(application.property.reload.listing_state).to eq("let_agreed")
  end
end
