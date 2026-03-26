require "rails_helper"

RSpec.describe Qa::DiagnosticsSnapshot do
  before do
    DemoData::ScenarioLoader.new.apply_catalog!(key: "baseline", actor_email: "spec@example.com")
  end

  it "summarizes runtime diagnostics and seeded personas" do
    snapshot = described_class.new.to_h

    expect(snapshot[:active_scenario]).to eq("Baseline Demo Estate")
    expect(snapshot[:mail_delivery_mode]).to eq(ActionMailer::Base.delivery_method.to_s)
    expect(snapshot[:job_adapter]).to be_present
    expect(snapshot[:seeded_personas]).to include("Admins:")
    expect(snapshot[:seeded_personas]).to include("Sellers:")
  end

  it "uses the translated label when the active scenario is a curated catalogue key" do
    BookingConfiguration.current.update!(active_demo_scenario_key: "custom_sevenoaks_westerham_catalogue")

    snapshot = described_class.new.to_h

    expect(snapshot[:active_scenario]).to eq("Curated Sevenoaks and Westerham catalogue")
  end
end
