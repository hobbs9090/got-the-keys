require "rails_helper"

RSpec.describe AppointmentEvent do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:property) do
    user.properties.create!(
      property_attributes(
        user_id: user.id,
        bathrooms: 2,
        property_type: "House",
        property_description: "A spacious detached home close to schools, green space, and commuter links."
      )
    )
  end
  let(:appointment) do
    property.appointments.create!(
      customer_name: "Jamie Seller",
      customer_email: "jamie@example.com",
      customer_phone: "07700 900111",
      requested_time: Time.zone.local(2026, 4, 2, 10, 0),
      scheduled_at: Time.zone.local(2026, 4, 2, 10, 0),
      duration_minutes: 45,
      status: "pending"
    )
  end

  around do |example|
    travel_to(Time.zone.local(2026, 4, 1, 8, 30)) { example.run }
  end

  it "defaults occurred_at before validation" do
    event = described_class.create!(
      appointment: appointment,
      event_type: "note_added",
      message: "Customer asked for parking details."
    )

    expect(event.occurred_at).to eq(Time.current)
  end

  it "keeps an explicitly provided occurred_at" do
    occurred_at = Time.zone.local(2026, 4, 1, 7, 0)
    event = described_class.create!(
      appointment: appointment,
      event_type: "created",
      message: "Initial request received.",
      occurred_at: occurred_at
    )

    expect(event.occurred_at).to eq(occurred_at)
  end

  it "orders timeline events chronologically" do
    later_event = described_class.create!(
      appointment: appointment,
      event_type: "confirmed",
      message: "Appointment confirmed.",
      occurred_at: Time.zone.local(2026, 4, 1, 13, 0)
    )
    earlier_event = described_class.create!(
      appointment: appointment,
      event_type: "created",
      message: "Appointment created.",
      occurred_at: Time.zone.local(2026, 4, 1, 9, 0)
    )

    expect(described_class.chronological.last(2)).to eq([earlier_event, later_event])
  end
end
