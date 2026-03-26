require "rails_helper"

RSpec.describe "Admin demo scenarios" do
  let(:admin) { FactoryBot.create(:admin, email: "steven@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  it "renders the demo data dashboard" do
    get admin_demo_scenarios_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Demo data management")
  end

  it "restores the baseline scenario" do
    post restore_baseline_admin_demo_scenarios_path

    expect(response).to redirect_to(admin_demo_scenarios_path)
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
    expect(Property.count).to eq(4)
    expect(Appointment.count).to eq(6)
  end

  it "renders the demo data dashboard in the admin's locale" do
    admin.update!(language: "de")

    get admin_demo_scenarios_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Demodatenverwaltung")
    expect(response.body).to include("Basis wiederherstellen")
    expect(response.body).to include("Vorschau")
  end
end
