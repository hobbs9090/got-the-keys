require "rails_helper"

RSpec.describe "Admin offers", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "offers-admin@gotthekeys.com", password: "secret123", password_confirmation: "secret123") }
  let(:offer) { FactoryBot.create(:offer, amount: 615_000) }

  before do
    sign_in admin
  end

  it "renders the offers board" do
    offer

    get admin_offers_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Offers board")
    expect(response.body).to include(%(data-testid="offers-column-received"))
  end

  it "updates an offer and syncs progression" do
    patch admin_offer_path(offer), params: {
      offer: {
        status: "accepted",
        chain_position: "Cash buyer, no chain",
        internal_notes: "Accepted after seller call."
      }
    }

    expect(response).to redirect_to(admin_offer_path(offer))
    expect(offer.reload.status).to eq("accepted")
    expect(offer.property.reload.listing_state).to eq("under_offer")
  end
end
