require "rails_helper"

RSpec.describe Offer do
  it "moves the property to under offer when accepted" do
    property = FactoryBot.create(:property)
    offer = FactoryBot.create(:offer, property:)

    offer.update!(status: "accepted")

    expect(property.reload.listing_state).to eq("under_offer")
    expect(offer.timeline.last.event_type).to eq("accepted")
  end

  it "rejects offers that use the property owner's email address" do
    property = FactoryBot.create(:property, user: FactoryBot.create(:user, email: "owner@example.com"))
    offer = FactoryBot.build(
      :offer,
      property:,
      buyer_email: "owner@example.com"
    )

    expect(offer).not_to be_valid
    expect(offer.errors[:buyer_email]).to include(I18n.t("ui.offers.validation.owner_cannot_offer"))
  end
end
