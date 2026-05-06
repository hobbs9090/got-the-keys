require "rails_helper"

RSpec.describe "Offers", type: :request do
  let(:property) { FactoryBot.create(:property, address_line_1: "15 Orchard Close") }
  let(:formatted_asking_price) { ApplicationController.helpers.number_with_delimiter(property.asking_price, delimiter: ",") }

  it "renders the public offer form" do
    get new_property_offer_path(property)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Submit an offer for 15 Orchard Close")

    document = Nokogiri::HTML.parse(response.body)
    summary = document.at_css('[data-testid="offer-property-summary"]')
    expect(summary).to be_present
    expect(summary.text).to include("15 Orchard Close")
    expect(summary.text).to include(ApplicationController.helpers.format_price(property))
    amount_input = document.at_css('[data-testid="offer-amount"]')
    increase_button = document.at_css('[data-testid="offer-amount-increase"]')
    decrease_button = document.at_css('[data-testid="offer-amount-decrease"]')

    expect(amount_input["value"]).to eq(formatted_asking_price)
    expect(amount_input["inputmode"]).to eq("numeric")
    expect(amount_input["pattern"]).to eq("[0-9,\\s]*")
    expect(amount_input["data-offer-amount-step"]).to eq("1000")
    expect(increase_button).to be_present
    expect(increase_button["type"]).to eq("button")
    expect(decrease_button).to be_present
    expect(decrease_button["type"]).to eq("button")
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

    expect(response).to redirect_to(offer_path(Offer.last.public_reference))
    expect(Offer.last.status).to eq("received")
  end

  it "does not let the owner open the offer form for their own property" do
    sign_in property.user

    get new_property_offer_path(property)

    expect(response).to redirect_to(property_path(property))
    follow_redirect!
    expect(response.body).to include(I18n.t("ui.offers.alerts.owner_cannot_offer"))
  end

  it "prefills the offer form with the signed-in user's details" do
    buyer = FactoryBot.create(
      :user,
      first_name: "Naomi",
      last_name: "Blake",
      email: "naomi@example.com",
      mobile_number: "07700 905100"
    )
    sign_in buyer

    get new_property_offer_path(property)

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)

    expect(document.at_css('[data-testid="offer-buyer-name"]')["value"]).to eq("Naomi Blake")
    email_display = document.at_css('[data-testid="offer-buyer-email-display"]')
    email_input = document.at_css('input[type="hidden"][name="offer[buyer_email]"]')

    expect(email_display.text).to include("naomi@example.com")
    expect(email_input["value"]).to eq("naomi@example.com")
    expect(document.at_css('[data-testid="offer-buyer-phone"]')["value"]).to eq("07700 905100")
    expect(document.at_css('[data-testid="offer-amount"]')["value"]).to eq(formatted_asking_price)
  end

  it "ignores a tampered buyer email for signed-in users" do
    buyer = FactoryBot.create(:user, email: "naomi@example.com")
    sign_in buyer

    expect do
      post property_offers_path(property), params: {
        offer: {
          buyer_name: "Naomi Blake",
          buyer_email: "tampered@example.com",
          buyer_phone: "07700 905100",
          amount: 575_000,
          chain_position: "Cash buyer",
          notes: "Flexible on completion timing."
        }
      }
    end.to change(Offer, :count).by(1)

    expect(Offer.last.buyer_email).to eq(buyer.email)
  end

  it "accepts a comma-separated amount when submitting an offer" do
    expect do
      post property_offers_path(property), params: {
        offer: {
          buyer_name: "Naomi Blake",
          buyer_email: "naomi@example.com",
          buyer_phone: "07700 905100",
          amount: "575,000",
          chain_position: "Cash buyer",
          notes: "Flexible on completion timing."
        }
      }
    end.to change(Offer, :count).by(1)

    expect(Offer.last.amount).to eq(575_000)
  end

  it "lets the signed-in buyer withdraw their own offer" do
    buyer = FactoryBot.create(:user, email: "naomi@example.com")
    offer = FactoryBot.create(:offer, property:, buyer_email: buyer.email, status: "received")
    sign_in buyer

    patch withdraw_property_offer_path(property, offer)

    expect(response).to redirect_to(mine_properties_path)
    expect(offer.reload.status).to eq("withdrawn")
  end

  it "does not let a signed-in user withdraw someone else's offer" do
    intruder = FactoryBot.create(:user, email: "intruder@example.com")
    offer = FactoryBot.create(:offer, property:, buyer_email: "buyer@example.com", status: "received")
    sign_in intruder

    patch withdraw_property_offer_path(property, offer)

    expect(response).to redirect_to(mine_properties_path)
    follow_redirect!
    expect(response.body).to include(I18n.t("ui.offers.alerts.not_your_offer"))
    expect(offer.reload.status).to eq("received")
  end

  it "does not let the owner submit an offer for their own property" do
    sign_in property.user

    expect do
      post property_offers_path(property), params: {
        offer: {
          buyer_name: property.user.full_name,
          buyer_email: property.user.email,
          buyer_phone: property.user.mobile_number,
          amount: 575_000,
          chain_position: "Owner",
          notes: "This should be rejected."
        }
      }
    end.not_to change(Offer, :count)

    expect(response).to redirect_to(property_path(property))
    follow_redirect!
    expect(response.body).to include(I18n.t("ui.offers.alerts.owner_cannot_offer"))
  end
end
