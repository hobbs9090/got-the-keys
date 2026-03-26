require "rails_helper"

RSpec.describe RentalApplication do
  it "moves the property to let agreed when approved" do
    property = FactoryBot.create(:property, :for_rent)
    application = FactoryBot.create(:rental_application, property:)

    application.update!(status: "approved")

    expect(property.reload.listing_state).to eq("let_agreed")
    expect(application.timeline.last.event_type).to eq("approved")
  end
end
