require "rails_helper"
require "nokogiri"

RSpec.describe "Admin offers", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "offers-admin@gotthekeys.com", password: "secret123", password_confirmation: "secret123") }
  let(:offer) { FactoryBot.create(:offer, amount: 615_000) }

  before do
    sign_in admin
  end

  it "renders the offers board" do
    offer

    get admin_sales_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Offers board")
    expect(response.body).to include(%(data-testid="offers-column-received"))

    document = Nokogiri::HTML.parse(response.body)
    buyer_link = document.at_css(%(a[href="#{admin_customer_path(offer.buyer_email.downcase)}"]))
    details_link = document.at_css(%([data-testid="admin-offer-open-#{offer.id}"]))

    expect(buyer_link).to be_present
    expect(buyer_link.text.strip).to eq(offer.buyer_name)
    expect(details_link).to be_present
    expect(details_link["href"]).to eq(admin_sale_path(offer))
    expect(details_link.text.strip).to eq("Details")
  end

  it "shows empty-state testid anchors on columns with no offers" do
    get admin_sales_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-testid="offers-column-empty-received"))
  end

  it "updates an offer and syncs progression" do
    patch admin_sale_path(offer), params: {
      offer: {
        status: "accepted",
        chain_position: "Cash buyer, no chain",
        internal_notes: "Accepted after seller call."
      }
    }

    expect(response).to redirect_to(admin_sale_path(offer))
    expect(offer.reload.status).to eq("accepted")
    expect(offer.property.reload.listing_state).to eq("under_offer")
  end
end
