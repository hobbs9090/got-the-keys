require "rails_helper"

RSpec.describe PropertyNextAvailableSlotLookup do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.zone.local(2026, 4, 1, 8, 0)) { example.run }
  end

  it "returns the same first next slot as the per-property availability service" do
    property = FactoryBot.create(:property)
    other_property = FactoryBot.create(:property)

    property.availability_windows.create!(
      kind: "open",
      starts_at: Time.zone.local(2026, 4, 1, 9, 0),
      ends_at: Time.zone.local(2026, 4, 1, 12, 0),
      capacity: 1
    )

    other_property.availability_windows.create!(
      kind: "group_viewing",
      starts_at: Time.zone.local(2026, 4, 1, 10, 0),
      ends_at: Time.zone.local(2026, 4, 1, 13, 0),
      capacity: 2
    )

    FactoryBot.create(
      :appointment,
      property: property,
      requested_time: Time.zone.local(2026, 4, 1, 9, 0),
      scheduled_at: Time.zone.local(2026, 4, 1, 9, 0),
      status: "confirmed",
      skip_slot_validation: true
    )

    slots = described_class.new(properties: [property, other_property]).call

    expect(slots.fetch(property.id)&.starts_at).to eq(property.next_available_slots(limit: 1).first&.starts_at)
    expect(slots.fetch(other_property.id)&.starts_at).to eq(other_property.next_available_slots(limit: 1).first&.starts_at)
  end
end
