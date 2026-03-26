require "rails_helper"

RSpec.describe DemoData::ScenarioLoader do
  subject(:loader) { described_class.new }

  before do
    ActionMailer::Base.deliveries.clear if defined?(ActionMailer::Base)
  end

  it "previews the bundled scenarios" do
    previews = loader.scenarios
    baseline = previews.find { |scenario| scenario[:key] == "baseline" }
    lifecycle = previews.find { |scenario| scenario[:key] == "listing_lifecycle" }
    leads = previews.find { |scenario| scenario[:key] == "lead_management" }
    viewing = previews.find { |scenario| scenario[:key] == "viewing_operations" }

    expect(previews.map { |scenario| scenario[:key] }).to include("baseline", "fully_booked_day", "qa_edge_cases", "high_volume_search", "listing_lifecycle", "lead_management", "viewing_operations")
    expect(baseline[:property_count]).to eq(4)
    expect(baseline[:appointment_count]).to eq(6)
    expect(baseline[:enquiry_count]).to eq(2)
    expect(baseline[:photo_count]).to eq(3)
    expect(lifecycle[:property_count]).to eq(5)
    expect(lifecycle[:photo_count]).to eq(3)
    expect(lifecycle[:floor_plan_count]).to eq(2)
    expect(leads[:enquiry_count]).to eq(5)
    expect(leads[:enquiry_statuses]).to include("new" => 2, "contacted" => 1, "qualified" => 1, "unqualified" => 1)
    expect(viewing[:appointment_statuses]).to include("confirmed" => 1, "rescheduled" => 1, "completed" => 1, "no_show" => 1)
  end

  it "applies a scenario and records the active key" do
    summary = loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com")

    expect(summary[:property_count]).to eq(4)
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
    expect(Admin.count).to eq(2)
    expect(User.count).to eq(4)
    expect(Property.count).to eq(4)
    expect(Photo.count).to eq(3)
    expect(FloorPlan.count).to eq(2)
    expect(Appointment.count).to eq(6)
    expect(Enquiry.count).to eq(2)
    expect(User.pluck(:language).uniq).to eq(["en"])
    expect(User.order(:email).pluck(:email)).to match_array([
      "charlotte.hughes@example.com",
      "daniel.mercer@example.com",
      "lucy.mcclure@example.com",
      "matthew.wells@example.com"
    ])
  end

  it "exports the current dataset as YAML" do
    loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com")
    exported = loader.export

    expect(exported).to include("Exported Snapshot")
    expect(exported).to include("baseline")
    expect(exported).to include("steven@gotthekeys.com")
    expect(exported).to include("photos:")
    expect(exported).to include("listing_state:")
    expect(exported).to include("enquiries:")
    expect(exported).to include("visit_outcome:")
  end
end
