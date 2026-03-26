require "rails_helper"

RSpec.describe "Offers", type: :request do
  let(:property) { FactoryBot.create(:property, address_line_1: "15 Orchard Close") }

  it "renders the public offer form" do
    get new_property_offer_path(property)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Submit an offer for 15 Orchard Close")
  end

  it "creates a public offer" do
    expect do
      post property_offers_path(property), params: {
        offer: {
          buyer_name: "Naomi Blake",
          buyer_email: "naomi@example.com",
          buyer_phone: "07700 905100",
          amount: 575_000,
          chain_position: "Cash buyer",
          notes: "Flexible on completion timing."
        }
      }
    end.to change(Offer, :count).by(1)

    expect(response).to redirect_to(property_path(property))
    expect(Offer.last.status).to eq("received")
  end
end
