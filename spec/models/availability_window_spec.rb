require "rails_helper"

RSpec.describe AvailabilityWindow do
  let(:user) { FactoryBot.create(:user) }
  let(:property) { user.properties.create!(property_attributes(user_id: user.id)) }

  it "is valid when the end time is after the start time" do
    window = described_class.new(
      property: property,
      kind: "open",
      starts_at: Time.zone.local(2026, 4, 1, 9, 0),
      ends_at: Time.zone.local(2026, 4, 1, 10, 0)
    )

    expect(window).to be_valid
  end

  it "is invalid when the end time is not after the start time" do
    window = described_class.new(
      property: property,
      kind: "open",
      starts_at: Time.zone.local(2026, 4, 1, 10, 0),
      ends_at: Time.zone.local(2026, 4, 1, 10, 0)
    )

    expect(window).not_to be_valid
    expect(window.errors[:ends_at]).to include("must be after the start time")
  end

  it "filters open windows in chronological order" do
    later_open = property.availability_windows.create!(
      kind: "open",
      starts_at: Time.zone.local(2026, 4, 2, 14, 0),
      ends_at: Time.zone.local(2026, 4, 2, 15, 0)
    )
    earlier_open = property.availability_windows.create!(
      kind: "open",
      starts_at: Time.zone.local(2026, 4, 2, 9, 0),
      ends_at: Time.zone.local(2026, 4, 2, 10, 0)
    )
    property.availability_windows.create!(
      kind: "blackout",
      starts_at: Time.zone.local(2026, 4, 2, 11, 0),
      ends_at: Time.zone.local(2026, 4, 2, 12, 0)
    )

    expect(described_class.open_windows).to eq([earlier_open, later_open])
  end

  it "filters blackout windows in chronological order" do
    later_blackout = property.availability_windows.create!(
      kind: "blackout",
      starts_at: Time.zone.local(2026, 4, 3, 14, 0),
      ends_at: Time.zone.local(2026, 4, 3, 15, 0)
    )
    earlier_blackout = property.availability_windows.create!(
      kind: "blackout",
      starts_at: Time.zone.local(2026, 4, 3, 9, 0),
      ends_at: Time.zone.local(2026, 4, 3, 10, 0)
    )

    expect(described_class.blackouts).to eq([earlier_blackout, later_blackout])
  end

  it "reports whether the window is open or blackout" do
    open_window = described_class.new(kind: "open")
    blackout_window = described_class.new(kind: "blackout")

    expect(open_window).to be_open
    expect(open_window).not_to be_blackout
    expect(blackout_window).to be_blackout
    expect(blackout_window).not_to be_open
  end
end
