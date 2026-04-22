require "rails_helper"

RSpec.describe RentalApplication do
  it "moves the property to let agreed when approved" do
    property = FactoryBot.create(:property, :for_rent)
    application = FactoryBot.create(:rental_application, property:)

    application.update!(status: "approved")

    expect(property.reload.listing_state).to eq("let_agreed")
    expect(application.timeline.last.event_type).to eq("approved")
  end

  it "does not move the property back to published when another approved application still exists" do
    property = FactoryBot.create(:property, :for_rent)
    app_a = FactoryBot.create(:rental_application, property:)
    app_b = FactoryBot.create(:rental_application, property:)

    app_a.update!(status: "approved")
    app_b.update!(status: "approved")

    app_a.update!(status: "rejected")

    expect(property.reload.listing_state).to eq("let_agreed")
  end
end
