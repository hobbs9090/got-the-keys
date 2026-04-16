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
    expect(response.body).to include("Append performance test data")
    expect(response.body).not_to include("Import scenario")
    expect(response.body).not_to include("Export current data")
    expect(response.body).not_to include("Scenario family")

    seed_reset_panel = parsed_html.at_css('[data-testid="scenario-seed-reset-panel"]')
    expect(seed_reset_panel).to be_present

    baseline_reset = parsed_html.at_css('[data-testid="scenario-seed-reset-baseline"]')
    expect(baseline_reset).to be_present
    expect(baseline_reset.text).to include(I18n.t("ui.admin.demo_data.scenario_keys.baseline"))

    baseline_input = baseline_reset.at_css('[data-testid="scenario-seed-reset-input-baseline"]')
    expect(baseline_input).to be_present
    expect(baseline_input["pattern"]).to eq("baseline")
    expect(baseline_input["placeholder"]).to eq("baseline")
    expect(response.body).not_to include(%(data-testid="scenario-card-high-volume-search"))
    expect(response.body).not_to include(%(data-testid="scenario-actions-high-volume-search"))

    performance_form = parsed_html.at_css('[data-testid="performance-seed-form"]')
    expect(performance_form).to be_present
    expect(parsed_html.at_css('[data-testid="performance-seed-user-count"]')["value"]).to eq(DemoData::Populator::DEFAULT_USER_COUNT.to_s)
    expect(parsed_html.at_css('[data-testid="performance-seed-property-count"]')["value"]).to eq(DemoData::Populator::DEFAULT_PROPERTY_COUNT.to_s)
    expect(parsed_html.at_css('[data-testid="performance-seed-password"]')["value"]).to eq("secret")
    expect(parsed_html.at_css('[data-testid="performance-seed-batch-size"]')["value"]).to eq(DemoData::Populator::DEFAULT_BATCH_SIZE.to_s)
  end

  it "restores the baseline scenario when the typed gate phrase is correct" do
    post restore_baseline_admin_demo_scenarios_path, params: { confirm_demo_scenario: "baseline", return_to: admin_demo_scenarios_path }

    expect(response).to redirect_to(admin_demo_scenarios_path)
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
    expect(Property.count).to eq(100)
    expect(Appointment.count).to eq(40)
    expect(Enquiry.count).to eq(40)
  end

  it "appends performance test data from the admin demo data dashboard" do
    expect do
      post populate_performance_admin_demo_scenarios_path, params: {
        performance_seed: {
          user_count: "3",
          property_count: "5",
          password: "benchmark-secret",
          ai_mode: "off",
          batch_size: "2",
          model: "gpt-5.4-mini"
        }
      }
    end.to change(User, :count).by(3)
      .and change(Property, :count).by(5)

    expect(response).to redirect_to(admin_demo_scenarios_path)
    expect(flash[:notice]).to eq("Added 3 users and 5 properties for performance testing.")

    latest_run = DemoScenarioRun.recent_first.first
    expect(latest_run.action_type).to eq("populate")
    expect(latest_run.initiated_by_email).to eq(admin.email)
    expect(latest_run.summary_data).to include(
      "users_added" => 3,
      "properties_added" => 5,
      "ai_mode" => "off",
      "batch_size" => 2
    )
  end

  it "re-renders the dashboard when performance seed parameters are invalid" do
    post populate_performance_admin_demo_scenarios_path, params: {
      performance_seed: {
        user_count: "0",
        property_count: "5",
        password: "secret",
        ai_mode: "off",
        batch_size: "2",
        model: "gpt-5.4-mini"
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Users to add must be 1 or greater.")
    expect(response.body).to include("Append performance test data")
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
    expect(response.body).to include(I18n.t("ui.admin.demo_data.preview.trainer_notes_title"))
    expect(response.body).to include(I18n.t("ui.admin.demo_data.preview.expected_assertions_title"))
    expect(response.body).to include(I18n.t("ui.admin.demo_data.scenario_expected_assertions.baseline").last)
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
