require "rails_helper"

RSpec.describe DemoData::ScenarioExporter do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) { FactoryBot.create(:admin, email: "ops@gotthekeys.com") }
  let(:user) { FactoryBot.create(:user, email: "owner@example.com", first_name: "Lina", last_name: "West") }
  let(:property) { FactoryBot.create(:property, user:, address_line_1: "7 Cedar Close", listing_tagline: "Light-filled family house") }
  let!(:photo) { FactoryBot.create(:photo, property:, image_filename: "cedar-close-front.jpg", primary: true, position: 1) }
  let!(:floor_plan) { FactoryBot.create(:floor_plan, property:, floor_plans: "cedar-close-plan.pdf", label: "Ground floor", position: 1) }
  let!(:window) do
    FactoryBot.create(
      :availability_window,
      property:,
      starts_at: booking_time(2026, 4, 6, 10, 0),
      ends_at: booking_time(2026, 4, 6, 11, 0),
      label: "Morning slot",
      notes: "Front door entry"
    )
  end
  let!(:appointment) do
    FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      admin: admin,
      customer_name: "Nina Hall",
      customer_email: "nina@example.com",
      customer_phone: "07700 900333",
      requested_time: booking_time(2026, 4, 6, 10, 0),
      scheduled_at: booking_time(2026, 4, 6, 10, 0),
      duration_minutes: 45,
      notes: "Please ring the side gate",
      internal_notes: "Vendor works from home"
    )
  end

  around do |example|
    travel_to(Time.zone.local(2026, 4, 5, 9, 0)) { example.run }
  end

  before do
    configure_booking_rules!(active_demo_scenario_key: "qa_snapshot")
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
      "featured" => false,
      "listing_state" => "published"
    )

    expect(payload["photos"]).to include(
      include("property_key" => property_payload.fetch("key"), "image_filename" => "cedar-close-front.jpg", "primary" => true)
    )
    expect(payload["floor_plans"]).to include(
      include("property_key" => property_payload.fetch("key"), "floor_plans" => "cedar-close-plan.pdf", "label" => "Ground floor")
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
