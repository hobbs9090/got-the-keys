require "rails_helper"

RSpec.describe Admin::AppointmentIndexQuery do
  include ActiveSupport::Testing::TimeHelpers

  let(:primary_property) { FactoryBot.create(:property, address_line_1: "18 Cedar Road") }
  let(:secondary_property) { FactoryBot.create(:property, address_line_1: "44 Mount Ephraim") }
  let(:primary_admin) { FactoryBot.create(:admin, email: "primary-admin@gotthekeys.com") }
  let(:secondary_admin) { FactoryBot.create(:admin, email: "secondary-admin@gotthekeys.com") }

  around do |example|
    travel_to(Time.zone.local(2026, 4, 1, 9, 0)) { example.run }
  end

  before do
    configure_booking_rules!
  end

  it "filters the agenda view by property, status, admin, and customer email" do
    matching = FactoryBot.create(
      :appointment,
      :confirmed,
      property: primary_property,
      admin: primary_admin,
      customer_name: "Matching Viewer",
      customer_email: "matching.viewer@example.com",
      requested_time: booking_time(2026, 4, 3, 9, 0),
      scheduled_at: booking_time(2026, 4, 3, 9, 0)
    )
    FactoryBot.create(
      :appointment,
      :pending,
      property: primary_property,
      admin: primary_admin,
      customer_email: "matching.viewer@example.com",
      requested_time: booking_time(2026, 4, 3, 11, 0),
      scheduled_at: booking_time(2026, 4, 3, 11, 0)
    )
    FactoryBot.create(
      :appointment,
      :confirmed,
      property: secondary_property,
      admin: primary_admin,
      customer_email: "matching.viewer@example.com",
      requested_time: booking_time(2026, 4, 3, 13, 0),
      scheduled_at: booking_time(2026, 4, 3, 13, 0)
    )
    FactoryBot.create(
      :appointment,
      :confirmed,
      property: primary_property,
      admin: secondary_admin,
      customer_email: "other.viewer@example.com",
      requested_time: booking_time(2026, 4, 20, 12, 0),
      scheduled_at: booking_time(2026, 4, 20, 12, 0)
    )

    result = described_class.new(
      params: {
        property_id: primary_property.id,
        status: "confirmed",
        admin_id: primary_admin.id,
        customer_email: "MATCHING.VIEWER@example.com"
      }
    ).call

    expect(result.view_mode).to eq("agenda")
    expect(result.anchor_date).to eq(Date.new(2026, 4, 1))
    expect(result.appointments.to_a).to eq([matching])
    expect(result.appointments_by_day.keys).to eq([Date.new(2026, 4, 3)])
    expect(result.calendar_days).to eq([])
  end

  it "uses explicit from and to dates when supplied" do
    in_range = FactoryBot.create(
      :appointment,
      property: primary_property,
      requested_time: booking_time(2026, 4, 10, 10, 0),
      scheduled_at: booking_time(2026, 4, 10, 10, 0)
    )
    FactoryBot.create(
      :appointment,
      property: primary_property,
      requested_time: booking_time(2026, 4, 13, 10, 0),
      scheduled_at: booking_time(2026, 4, 13, 10, 0)
    )

    result = described_class.new(params: { from: "2026-04-10", to: "2026-04-11" }).call

    expect(result.appointments.to_a).to eq([in_range])
  end

  it "orders bookings from earliest to latest scheduled time" do
    later = FactoryBot.create(
      :appointment,
      property: primary_property,
      requested_time: booking_time(2026, 4, 3, 15, 0),
      scheduled_at: booking_time(2026, 4, 3, 15, 0)
    )
    earlier = FactoryBot.create(
      :appointment,
      property: primary_property,
      requested_time: booking_time(2026, 4, 2, 10, 0),
      scheduled_at: booking_time(2026, 4, 2, 10, 0)
    )
    same_time_later_created = FactoryBot.create(
      :appointment,
      property: primary_property,
      requested_time: booking_time(2026, 4, 2, 10, 0),
      scheduled_at: booking_time(2026, 4, 2, 10, 0)
    )
    earlier.update_columns(created_at: Time.zone.local(2026, 4, 1, 9, 5), updated_at: Time.zone.local(2026, 4, 1, 9, 5))
    same_time_later_created.update_columns(created_at: Time.zone.local(2026, 4, 1, 9, 10), updated_at: Time.zone.local(2026, 4, 1, 9, 10))

    result = described_class.new(params: {}).call

    expect(result.appointments.first(3)).to eq([earlier, same_time_later_created, later])
  end

  it "builds the calendar grid for week view from the requested anchor date" do
    friday_booking = FactoryBot.create(
      :appointment,
      property: primary_property,
      requested_time: booking_time(2026, 4, 3, 15, 0),
      scheduled_at: booking_time(2026, 4, 3, 15, 0)
    )
    FactoryBot.create(
      :appointment,
      property: primary_property,
      requested_time: booking_time(2026, 4, 6, 15, 0),
      scheduled_at: booking_time(2026, 4, 6, 15, 0)
    )

    result = described_class.new(params: { view: "week", date: "2026-04-02" }).call

    expect(result.view_mode).to eq("week")
    expect(result.anchor_date).to eq(Date.new(2026, 4, 2))
    expect(result.calendar_days).to eq((Date.new(2026, 3, 30)..Date.new(2026, 4, 5)).to_a)
    expect(result.appointments.to_a).to eq([friday_booking])
    expect(result.appointments_by_day.keys).to eq([Date.new(2026, 4, 3)])
  end
end
