require "rails_helper"
require "nokogiri"

RSpec.describe "Admin demo scenarios" do
  let(:admin) { FactoryBot.create(:admin, email: "steven@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  it "renders the demo data dashboard with a seed reset danger zone" do
    get admin_demo_scenarios_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Demo data management")
    expect(response.body).to include("Seed data resets")
    expect(response.body).not_to include("Quick reset packs")

    seed_reset_panel = parsed_html.at_css('[data-testid="scenario-seed-reset-panel"]')
    expect(seed_reset_panel).to be_present

    baseline_reset = parsed_html.at_css('[data-testid="scenario-seed-reset-baseline"]')
    expect(baseline_reset).to be_present
    expect(baseline_reset.text).to include("Baseline Demo Estate")

    baseline_input = baseline_reset.at_css('[data-testid="scenario-seed-reset-input-baseline"]')
    expect(baseline_input).to be_present
    expect(baseline_input["pattern"]).to eq("baseline")
    expect(baseline_input["placeholder"]).to eq("baseline")

    expect(response.body).to include(%(data-testid="scenario-complexity-high-volume-search"))
    expect(response.body).to include(%(data-testid="scenario-actions-high-volume-search"))
  end

  it "restores the baseline scenario when the typed gate phrase is correct" do
    post restore_baseline_admin_demo_scenarios_path, params: { confirm_demo_scenario: "baseline", return_to: admin_demo_scenarios_path }

    expect(response).to redirect_to(admin_demo_scenarios_path)
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
    expect(Property.count).to eq(4)
    expect(Appointment.count).to eq(6)
  end

  it "rejects quick reset requests without the typed gate phrase" do
    post apply_admin_demo_scenario_path("deal_progression"), params: { confirm_demo_scenario: "wrong-key", return_to: admin_demo_scenarios_path }

    expect(response).to redirect_to(admin_demo_scenarios_path)

    follow_redirect!

    expect(response.body).to include("Type deal_progression exactly to run this seed reset.")
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
  end

  it "renders the demo data dashboard in the admin's locale" do
    admin.update!(language: "de")

    get admin_demo_scenarios_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Demodatenverwaltung")
    expect(response.body).to include("Seed-Daten-Resets")
    expect(response.body).to include("Vorschau")
  end

  it "renders trainer notes and expected assertions on the preview page" do
    get admin_demo_scenario_path("documents_and_trust")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Trainer notes")
    expect(response.body).to include("Expected assertions")
    expect(response.body).to include("public pages should expose brochure files".capitalize)
  end

  it "shows the typed gate on quick reset preview pages" do
    get admin_demo_scenario_path("baseline")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Seed data reset")
    expect(response.body).not_to include("Apply scenario")

    preview_reset = parsed_html.at_css('[data-testid="scenario-seed-reset-preview-panel"]')
    expect(preview_reset).to be_present
    expect(preview_reset.at_css('[data-testid="scenario-seed-reset-input-baseline"]')).to be_present
  end
end
