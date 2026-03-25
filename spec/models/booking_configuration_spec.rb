require "rails_helper"

RSpec.describe BookingConfiguration do
  def build_configuration(overrides = {})
    BookingConfiguration.new(
      {
        slot_duration_minutes: 45,
        lead_time_hours: 4,
        buffer_minutes: 15,
        office_opens_at: "09:00",
        office_closes_at: "18:00",
        open_weekdays: %w[1 2 3 4 5]
      }.merge(overrides)
    )
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
