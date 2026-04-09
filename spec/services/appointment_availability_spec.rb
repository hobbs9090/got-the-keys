require "rails_helper"

RSpec.describe AppointmentAvailability do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin, email: "scheduler@gotthekeys.test") }
  let(:property) { FactoryBot.create(:property, user:, address_line_1: "18 Cedar Road") }
  let(:configuration) { BookingConfiguration.current }

  before do
    configure_booking_rules!
  end

  around do |example|
    travel_to(Time.zone.local(2026, 3, 30, 8, 0)) { example.run }
  end

  it "returns slots from explicit open windows on otherwise closed days" do
    FactoryBot.create(
      :availability_window,
      property:,
      kind: "open",
      starts_at: booking_time(2026, 4, 5, 10, 0),
      ends_at: booking_time(2026, 4, 5, 12, 0)
    )

    sunday_morning = booking_time(2026, 4, 5, 9, 0)
    slots = described_class.new(property: property, configuration: configuration, from: sunday_morning).next_slots(limit: 2, days_ahead: 0)

    expect(slots.map(&:starts_at)).to eq(
      [
        booking_time(2026, 4, 5, 10, 0),
        booking_time(2026, 4, 5, 10, 15)
      ]
    )
  end

  it "offers quarter-hour start times within each available window" do
    FactoryBot.create(
      :availability_window,
      property:,
      kind: "open",
      starts_at: booking_time(2026, 4, 1, 10, 0),
      ends_at: booking_time(2026, 4, 1, 12, 0)
    )

    slots = described_class.new(property: property, configuration: configuration, from: booking_time(2026, 4, 1, 9, 0)).next_slots(limit: 4, days_ahead: 0)

    expect(slots.map(&:starts_at)).to eq(
      [
        booking_time(2026, 4, 1, 10, 0),
        booking_time(2026, 4, 1, 10, 15),
        booking_time(2026, 4, 1, 10, 30),
        booking_time(2026, 4, 1, 10, 45)
      ]
    )
  end

  it "rounds the first available slot up to the next quarter hour" do
    slots = described_class.new(
      property: property,
      configuration: configuration,
      from: booking_time(2026, 4, 1, 9, 7) + 23.seconds
    ).next_slots(limit: 1, days_ahead: 0)

    expect(slots.first.starts_at).to eq(booking_time(2026, 4, 1, 9, 15))
  end

  it "uses the configured booking window by default" do
    configuration.update!(booking_window_days: 14)

    slots = described_class.new(property: property, configuration: configuration, from: booking_time(2026, 4, 1, 8, 0)).next_slots(limit: 500)

    expect(slots.map { |slot| slot.starts_at.to_date }.uniq.last).to eq(Date.new(2026, 4, 15))
  end

  it "rejects future slots that fall inside the lead time" do
    availability = described_class.new(property: property, configuration: configuration)

    expect(availability.slot_available?(booking_time(2026, 3, 30, 11, 0), duration_minutes: 45)).to be(false)
    expect(availability.slot_available?(booking_time(2026, 3, 30, 12, 0), duration_minutes: 45)).to be(true)
  end

  it "rejects slots that overlap blackouts" do
    FactoryBot.create(
      :availability_window,
      :blackout,
      property:,
      starts_at: booking_time(2026, 3, 30, 13, 0),
      ends_at: booking_time(2026, 3, 30, 14, 0)
    )

    availability = described_class.new(property: property, configuration: configuration)

    expect(availability.slot_available?(booking_time(2026, 3, 30, 13, 15), duration_minutes: 45)).to be(false)
    expect(availability.slot_available?(booking_time(2026, 3, 30, 14, 0), duration_minutes: 45)).to be(true)
  end

  it "treats blocking appointments as unavailable unless they are excluded" do
    appointment = FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      admin: admin,
      customer_name: "Nina Hughes",
      customer_email: "nina.hughes@example.com",
      customer_phone: "07700 930005",
      requested_time: booking_time(2026, 3, 30, 14, 0),
      scheduled_at: booking_time(2026, 3, 30, 14, 0),
      duration_minutes: 45
    )

    availability = described_class.new(property: property, configuration: configuration)
    rescheduled_start = booking_time(2026, 3, 30, 14, 45)

    expect(availability.slot_available?(rescheduled_start, duration_minutes: 45)).to be(false)
    expect(availability.slot_available?(rescheduled_start, duration_minutes: 45, excluding_appointment: appointment)).to be(true)
  end

  it "allows grouped viewing slots up to the configured window capacity" do
    slot = booking_time(2026, 4, 4, 10, 0)
    FactoryBot.create(
      :availability_window,
      :group_viewing,
      property:,
      starts_at: booking_time(2026, 4, 4, 10, 0),
      ends_at: booking_time(2026, 4, 4, 12, 0),
      capacity: 3
    )

    2.times do |index|
      FactoryBot.create(
        :appointment,
        :confirmed,
        property:,
        admin: admin,
        customer_name: "Group Viewer #{index + 1}",
        customer_email: "group#{index + 1}@example.com",
        customer_phone: format("07700 9301%02d", index),
        requested_time: slot,
        scheduled_at: slot,
        duration_minutes: 45
      )
    end

    availability = described_class.new(property: property, configuration: configuration, from: booking_time(2026, 4, 4, 8, 0))

    expect(availability.slot_available?(slot, duration_minutes: 45)).to be(true)

    FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      admin: admin,
      customer_name: "Group Viewer 3",
      customer_email: "group3@example.com",
      customer_phone: "07700 930199",
      requested_time: slot,
      scheduled_at: slot,
      duration_minutes: 45
    )

    expect(availability.slot_available?(slot, duration_minutes: 45)).to be(false)
  end

end
