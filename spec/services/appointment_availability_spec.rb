require "rails_helper"

RSpec.describe AppointmentAvailability do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin, email: "scheduler@gotthekeys.test") }
  let(:property) do
    user.properties.create!(
      property_attributes(
        user_id: user.id,
        address_line_1: "18 Cedar Road",
        bathrooms: 2,
        property_type: "House",
        property_description: "A bright detached family home with generous living space and a long rear garden."
      )
    )
  end
  let(:configuration) { BookingConfiguration.current }

  before do
    configuration.update!(
      slot_duration_minutes: 45,
      lead_time_hours: 4,
      buffer_minutes: 15,
      office_opens_at: "09:00",
      office_closes_at: "17:00",
      open_weekdays: %w[1 2 3 4 5]
    )
  end

  around do |example|
    travel_to(Time.zone.local(2026, 3, 30, 8, 0)) { example.run }
  end

  it "returns slots from explicit open windows on otherwise closed days" do
    property.availability_windows.create!(
      kind: "open",
      starts_at: Time.zone.local(2026, 4, 5, 10, 0),
      ends_at: Time.zone.local(2026, 4, 5, 12, 0)
    )

    sunday_morning = Time.zone.local(2026, 4, 5, 9, 0)
    slots = described_class.new(property: property, configuration: configuration, from: sunday_morning).next_slots(limit: 2, days_ahead: 0)

    expect(slots.map(&:starts_at)).to eq(
      [
        Time.zone.local(2026, 4, 5, 10, 0),
        Time.zone.local(2026, 4, 5, 10, 45)
      ]
    )
  end

  it "rejects future slots that fall inside the lead time" do
    availability = described_class.new(property: property, configuration: configuration)

    expect(availability.slot_available?(Time.zone.local(2026, 3, 30, 11, 0), duration_minutes: 45)).to be(false)
    expect(availability.slot_available?(Time.zone.local(2026, 3, 30, 12, 0), duration_minutes: 45)).to be(true)
  end

  it "rejects slots that overlap blackouts" do
    property.availability_windows.create!(
      kind: "blackout",
      starts_at: Time.zone.local(2026, 3, 30, 13, 0),
      ends_at: Time.zone.local(2026, 3, 30, 14, 0)
    )

    availability = described_class.new(property: property, configuration: configuration)

    expect(availability.slot_available?(Time.zone.local(2026, 3, 30, 13, 15), duration_minutes: 45)).to be(false)
    expect(availability.slot_available?(Time.zone.local(2026, 3, 30, 14, 0), duration_minutes: 45)).to be(true)
  end

  it "treats blocking appointments as unavailable unless they are excluded" do
    appointment = property.appointments.create!(
      admin: admin,
      customer_name: "Nina Hughes",
      customer_email: "nina.hughes@example.com",
      customer_phone: "07700 930005",
      requested_time: Time.zone.local(2026, 3, 30, 14, 0),
      scheduled_at: Time.zone.local(2026, 3, 30, 14, 0),
      duration_minutes: 45,
      status: "confirmed"
    )

    availability = described_class.new(property: property, configuration: configuration)
    rescheduled_start = Time.zone.local(2026, 3, 30, 14, 45)

    expect(availability.slot_available?(rescheduled_start, duration_minutes: 45)).to be(false)
    expect(availability.slot_available?(rescheduled_start, duration_minutes: 45, excluding_appointment: appointment)).to be(true)
  end
end
