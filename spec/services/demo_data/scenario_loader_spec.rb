require "rails_helper"

RSpec.describe DemoData::ScenarioLoader do
  subject(:loader) { described_class.new }

  before do
    ActionMailer::Base.deliveries.clear if defined?(ActionMailer::Base)
  end

  it "previews the bundled scenarios" do
    previews = loader.scenarios
    baseline = previews.find { |scenario| scenario[:key] == "baseline" }

    expect(previews.map { |scenario| scenario[:key] }).to include("baseline", "fully_booked_day", "qa_edge_cases", "high_volume_search")
    expect(baseline[:property_count]).to eq(4)
    expect(baseline[:appointment_count]).to eq(6)
  end

  it "applies a scenario and records the active key" do
    summary = loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com")

    expect(summary[:property_count]).to eq(4)
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
    expect(Admin.count).to eq(2)
    expect(User.count).to eq(4)
    expect(Property.count).to eq(4)
    expect(Appointment.count).to eq(6)
    expect(User.pluck(:language).uniq).to eq(["en"])
    expect(User.order(:email).pluck(:email)).to match_array([
      "charlotte.hughes@gmail.example",
      "daniel.mercer@outlook.example",
      "lucy.mcclure@btinternet.example",
      "matthew.wells@icloud.example"
    ])
  end

  it "exports the current dataset as YAML" do
    loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com")
    exported = loader.export

    expect(exported).to include("Exported Snapshot")
    expect(exported).to include("baseline")
    expect(exported).to include("steven@gotthekeys.com")
  end
end
