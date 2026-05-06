require "rails_helper"

RSpec.describe "Offer progression", type: :system do
  def sign_in_as_user(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "changeme123"
    click_button "Sign in"
  end

  def sign_in_as(admin)
    visit admin_sales_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: "changeme123"
    click_button "Sign in"
    visit admin_sales_path
  end

  it "lets a buyer submit an offer and an admin accept it" do
    property = FactoryBot.create(:property, address_line_1: "19 Willow Road")
    admin = FactoryBot.create(:admin, email: "offers-board@gotthekeys.com", password: "changeme123", password_confirmation: "changeme123")
    buyer = FactoryBot.create(:user, email: "offer-buyer@example.com", password: "changeme123", password_confirmation: "changeme123")

    sign_in_as_user(buyer)

    visit property_path(property)
    click_link "Submit an offer"

    within('[data-testid="property-offer-form"]') do
      fill_in "offer_buyer_name", with: "Nina Hughes"
      expect(page).to have_css('[data-testid="offer-buyer-email-display"]', text: buyer.email)
      fill_in "offer_buyer_phone", with: "07700 905555"
      fill_in "offer_amount", with: "620000"
      fill_in "offer_chain_position", with: "Cash buyer"
      fill_in "offer_notes", with: "Flexible on completion and keen to move quickly."
      click_button "Submit offer"
    end

    offer = Offer.order(:created_at).last

    sign_in_as(admin)
    click_link "Details"
    select I18n.t("ui.offers.statuses.accepted"), from: "offer_status"
    fill_in "offer_internal_notes", with: "Seller accepted headline amount."
    click_button "Save offer"

    expect(page).to have_text("Offer updated.")
    expect(offer.reload.status).to eq("accepted")
    expect(property.reload.listing_state).to eq("under_offer")
  end
end
