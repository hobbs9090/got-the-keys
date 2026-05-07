require "rails_helper"

RSpec.describe Qa::DiagnosticsSnapshot do
  before do
    DemoData::ScenarioLoader.new.apply_catalog!(key: "baseline", actor_email: "spec@example.com")
  end

  it "summarizes runtime diagnostics and seeded personas" do
    snapshot = described_class.new.to_h

    expect(snapshot[:active_scenario]).to eq(I18n.t("ui.admin.demo_data.scenario_keys.baseline"))
    expect(snapshot[:mail_delivery_mode]).to eq(ActionMailer::Base.delivery_method.to_s)
    expect(snapshot[:job_adapter]).to be_present
    expect(snapshot[:seeded_personas]).to be_a(Hash)
    expect(snapshot[:seeded_personas][:admins]).to include("steven@gotthekeys.uk / secret1234", "kate@gotthekeys.uk / secret1234")
    expect(snapshot[:seeded_personas][:sellers].size).to eq(88)
    expect(snapshot[:seeded_personas][:buyers].size).to eq(4)
    expect(snapshot[:seeded_personas][:sellers]).to include("Hans Schmidt (Deutsch) - hans.schmidt@example.com / secret1234")
    expect(snapshot[:seeded_personas][:sellers]).to include("Holly Wade (English) - holly.wade@example.com / secret1234")
    expect(snapshot[:seeded_personas][:buyers]).to include("Nina Hughes (English) - nina.hughes@example.com / secret1234")
    expect(snapshot[:seeded_personas][:buyers]).to include("Alex Cole (English) - alex.cole@example.com / secret1234")
  end

  it "uses the translated label when the active scenario is a curated catalogue key" do
    BookingConfiguration.current.update!(active_demo_scenario_key: "custom_sevenoaks_westerham_catalogue")

    snapshot = described_class.new.to_h

    expect(snapshot[:active_scenario]).to eq("Curated Sevenoaks and Westerham catalogue")
  end
end
