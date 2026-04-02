require "rails_helper"
require "nokogiri"

RSpec.describe "Admin demo scenarios" do
  let(:admin) { FactoryBot.create(:admin, email: "steven@gotthekeys.uk", password: "changeme", password_confirmation: "changeme") }

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
    expect(response.body).not_to include("Import scenario")
    expect(response.body).not_to include("Export current data")
    expect(response.body).not_to include("Scenario family")

    seed_reset_panel = parsed_html.at_css('[data-testid="scenario-seed-reset-panel"]')
    expect(seed_reset_panel).to be_present

    baseline_reset = parsed_html.at_css('[data-testid="scenario-seed-reset-baseline"]')
    expect(baseline_reset).to be_present
    expect(baseline_reset.text).to include("Baseline Demo Estate")

    baseline_input = baseline_reset.at_css('[data-testid="scenario-seed-reset-input-baseline"]')
    expect(baseline_input).to be_present
    expect(baseline_input["pattern"]).to eq("baseline")
    expect(baseline_input["placeholder"]).to eq("baseline")
    expect(response.body).not_to include(%(data-testid="scenario-card-high-volume-search"))
    expect(response.body).not_to include(%(data-testid="scenario-actions-high-volume-search"))
  end

  it "restores the baseline scenario when the typed gate phrase is correct" do
    post restore_baseline_admin_demo_scenarios_path, params: { confirm_demo_scenario: "baseline", return_to: admin_demo_scenarios_path }

    expect(response).to redirect_to(admin_demo_scenarios_path)
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
    expect(Property.count).to eq(100)
    expect(Appointment.count).to eq(40)
    expect(Enquiry.count).to eq(40)
  end

  it "rejects direct admin access to non-baseline scenarios" do
    get admin_demo_scenario_path("removed_scenario")

    expect(response).to redirect_to(admin_demo_scenarios_path)

    follow_redirect!

    expect(response.body).to include("Only the baseline demo dataset is available here right now.")
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
  end

  it "renders the demo data dashboard in the admin's locale" do
    admin.update!(language: "de")

    get admin_demo_scenarios_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Demodatenverwaltung")
    expect(response.body).to include("Seed-Daten-Resets")
    expect(response.body).not_to include("Vorschau")
  end

  it "renders trainer notes and expected assertions on the baseline preview page" do
    get admin_demo_scenario_path("baseline")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Trainer notes")
    expect(response.body).to include("Expected assertions")
    expect(response.body).to include("Known admin and seller credentials should appear in the QA guide.")
  end

  it "shows the typed gate on quick reset preview pages" do
    get admin_demo_scenario_path("baseline")

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Seed data reset")
    expect(response.body).not_to include("Apply scenario")
    expect(response.body).not_to include("Typed gate")

    preview_reset = parsed_html.at_css('[data-testid="scenario-seed-reset-preview-panel"]')
    expect(preview_reset).to be_present
    expect(preview_reset.at_css('[data-testid="scenario-seed-reset-input-baseline"]')).to be_present
  end
end
