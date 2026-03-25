require "rails_helper"

RSpec.describe DemoData::ScenarioExporter do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { FactoryBot.create(:admin, email: "ops@gotthekeys.com") }
  let(:user) { FactoryBot.create(:user, email: "owner@example.com", first_name: "Lina", last_name: "West") }
  let(:property) do
    user.properties.create!(
      property_attributes(
        user_id: user.id,
        address_line_1: "7 Cedar Close",
        bathrooms: 2,
        property_type: "House",
        listing_tagline: "Light-filled family house",
        property_description: "A bright, extended family house with a practical kitchen diner and a generous rear garden."
      )
    )
  end
  let!(:window) do
    property.availability_windows.create!(
      starts_at: Time.zone.local(2026, 4, 6, 10, 0),
      ends_at: Time.zone.local(2026, 4, 6, 11, 0),
      kind: "open",
      label: "Morning slot",
      notes: "Front door entry"
    )
  end
  let!(:appointment) do
    property.appointments.create!(
      admin: admin,
      customer_name: "Nina Hall",
      customer_email: "nina@example.com",
      customer_phone: "07700 900333",
      requested_time: Time.zone.local(2026, 4, 6, 10, 0),
      scheduled_at: Time.zone.local(2026, 4, 6, 10, 0),
      duration_minutes: 45,
      status: "confirmed",
      notes: "Please ring the side gate",
      internal_notes: "Vendor works from home"
    )
  end

  around do |example|
    travel_to(Time.zone.local(2026, 4, 5, 9, 0)) { example.run }
  end

  before do
    BookingConfiguration.current.update!(active_demo_scenario_key: "qa_snapshot")
  end

  it "exports the current dataset as normalized YAML" do
    payload = YAML.safe_load(described_class.new.export, permitted_classes: [Date, Time], aliases: false)

    expect(payload["key"]).to eq("qa_snapshot")
    expect(payload["name"]).to eq("Exported Snapshot")
    expect(payload["admins"]).to include(
      include("email" => "ops@gotthekeys.com", "password" => "secret", "password_confirmation" => "secret")
    )
    expect(payload["users"]).to include(
      include("email" => "owner@example.com", "password" => "secret", "password_confirmation" => "secret")
    )

    property_payload = payload["properties"].find { |entry| entry["address_line_1"] == "7 Cedar Close" }
    expect(property_payload).to include(
      "owner_email" => "owner@example.com",
      "listing_tagline" => "Light-filled family house",
      "featured" => false
    )

    expect(payload["availability_windows"]).to include(
      include("property_key" => property_payload.fetch("key"), "kind" => "open", "label" => "Morning slot")
    )
    expect(payload["appointments"]).to include(
      include(
        "property_key" => property_payload.fetch("key"),
        "assigned_admin_email" => "ops@gotthekeys.com",
        "customer_email" => "nina@example.com",
        "status" => "confirmed"
      )
    )
  end
end
