require "rails_helper"

RSpec.describe Offer do
  it "moves the property to under offer when accepted" do
    property = FactoryBot.create(:property)
    offer = FactoryBot.create(:offer, property:)

    offer.update!(status: "accepted")

    expect(property.reload.listing_state).to eq("under_offer")
    expect(offer.timeline.last.event_type).to eq("accepted")
  end
end
