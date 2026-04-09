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

  it "only allows supported slot durations" do
    configuration = build_configuration(slot_duration_minutes: 50)

    expect(configuration).not_to be_valid
    expect(configuration.errors[:slot_duration_minutes]).to include("is not included in the list")
  end

  it "requires the booking window to stay within a sensible range" do
    configuration = build_configuration(booking_window_days: 0)

    expect(configuration).not_to be_valid
    expect(configuration.errors[:booking_window_days]).to include("must be greater than or equal to 1")
  end
end
