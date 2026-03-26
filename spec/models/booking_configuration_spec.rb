require "rails_helper"

RSpec.describe BookingConfiguration do
  def build_configuration(overrides = {})
    FactoryBot.build(:booking_configuration, { office_closes_at: "18:00" }.merge(overrides))
  end

  it "requires office times in HH:MM format" do
    configuration = build_configuration(office_opens_at: "9am")

    expect(configuration).not_to be_valid
    expect(configuration.errors[:office_opens_at]).to include("must use 24-hour HH:MM format")
  end

  it "requires at least one open weekday" do
    configuration = build_configuration(open_weekdays: [])

    expect(configuration).not_to be_valid
    expect(configuration.errors[:open_weekdays]).to include("must include at least one day")
  end
end
