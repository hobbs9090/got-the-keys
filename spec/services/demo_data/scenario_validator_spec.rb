require "rails_helper"

RSpec.describe DemoData::ScenarioValidator do
  include ActiveSupport::Testing::TimeHelpers

  let(:validator) { described_class.new }
  let(:base_payload) do
    {
      key: "baseline",
      name: "Baseline",
      booking_configuration: {
        slot_duration_minutes: 30,
        lead_time_hours: 2,
        buffer_minutes: 10,
        office_opens_at: "08:30",
        office_closes_at: "17:30",
        open_weekdays: [1, 2, 3, 4, 5]
      },
      admins: [
        { email: "admin@example.com", password: "secret" }
      ],
      users: [
        {
          first_name: "Jordan",
          last_name: "Lee",
          mobile_number: "07700 900444",
          email: "owner@example.com"
        }
      ],
      properties: [
        {
          key: "cedar-close",
          owner_email: "owner@example.com",
          address_line_1: "7 Cedar Close",
          town_city: "Sevenoaks",
          county: "Kent",
          postcode: "TN13 1AA",
          country: "United Kingdom",
          property_description: "A bright detached house with open-plan reception space, modern finishes, and a landscaped garden.",
          bedrooms: 4,
          sale_status: "For Sale",
          asking_price: 650000
        }
      ],
      availability_windows: [
        {
          property_key: "cedar-close",
          starts_at: "today+2d 10:00",
          ends_at: "today+2d 11:00",
          kind: "open"
        }
      ],
      appointments: [
        {
          property_key: "cedar-close",
          assigned_admin_email: "admin@example.com",
          customer_name: "Nina Hall",
          customer_email: "nina@example.com",
          customer_phone: "07700 900333",
          requested_time: "today+2d 10:00",
          status: "confirmed"
        }
      ]
    }
  end

  around do |example|
    travel_to(Time.zone.local(2026, 4, 1, 9, 0)) { example.run }
  end

  before do
    BookingConfiguration.current.update!(slot_duration_minutes: 45)
  end

  it "normalizes a valid scenario payload" do
    normalized = validator.validate!(base_payload)

    expect(normalized[:booking_configuration]).to include(
      slot_duration_minutes: 30,
      lead_time_hours: 2,
      buffer_minutes: 10,
      office_opens_at: "08:30",
      office_closes_at: "17:30",
      open_weekdays: [1, 2, 3, 4, 5]
    )
    expect(normalized[:admins]).to include(
      include(email: "admin@example.com", password_confirmation: "secret", language: "en")
    )
    expect(normalized[:users]).to include(
      include(email: "owner@example.com", terms_of_service: true, language: "en")
    )
    expect(normalized[:properties]).to include(
      include(key: "cedar-close", bathrooms: 1, property_type: "House", featured: false)
    )
    expect(normalized[:availability_windows]).to include(
      include(
        property_key: "cedar-close",
        starts_at: Time.zone.local(2026, 4, 3, 10, 0),
        ends_at: Time.zone.local(2026, 4, 3, 11, 0)
      )
    )
    expect(normalized[:appointments]).to include(
      include(
        property_key: "cedar-close",
        assigned_admin_email: "admin@example.com",
        scheduled_at: Time.zone.local(2026, 4, 3, 10, 0),
        duration_minutes: 30,
        status: "confirmed"
      )
    )
  end

  it "falls back to the current booking configuration duration when one is not provided" do
    payload = base_payload.deep_dup
    payload[:booking_configuration].delete(:slot_duration_minutes)
    payload[:appointments].first.delete(:duration_minutes)

    normalized = validator.validate!(payload)

    expect(normalized[:appointments].first[:duration_minutes]).to eq(45)
  end

  it "raises when a property references a missing owner email" do
    payload = base_payload.deep_dup
    payload[:properties].first[:owner_email] = "missing@example.com"

    expect { validator.validate!(payload) }.to raise_error(
      described_class::ValidationError,
      "Property cedar-close references missing owner email missing@example.com"
    )
  end

  it "raises when an appointment references an unknown admin email" do
    payload = base_payload.deep_dup
    payload[:appointments].first[:assigned_admin_email] = "missing-admin@example.com"

    expect { validator.validate!(payload) }.to raise_error(
      described_class::ValidationError,
      "Appointment references unknown admin email missing-admin@example.com"
    )
  end

  it "raises when an appointment uses an unsupported status" do
    payload = base_payload.deep_dup
    payload[:appointments].first[:status] = "queued"

    expect { validator.validate!(payload) }.to raise_error(
      described_class::ValidationError,
      'Unsupported appointment status "queued"'
    )
  end

  it "summarizes a validated scenario preview" do
    preview = validator.preview(base_payload)

    expect(preview).to include(
      key: "baseline",
      name: "Baseline",
      admin_count: 1,
      user_count: 1,
      property_count: 1,
      availability_window_count: 1,
      appointment_count: 1,
      appointment_statuses: { "confirmed" => 1 }
    )
  end
end
