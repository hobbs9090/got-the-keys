require "rails_helper"

RSpec.describe "Admin demo scenarios", type: :system do
  def sign_in_as(email:, password:)
    visit admin_demo_scenarios_path

    fill_in "admin_email", with: email
    fill_in "admin_password", with: password
    click_button "Sign in"
  end

  it "restores the baseline scenario from the admin area with the typed gate" do
    BookingConfiguration.current.update!(active_demo_scenario_key: "fully_booked_day")
    admin = FactoryBot.create(:admin, email: "steven@gotthekeys.com", password: "changeme", password_confirmation: "changeme")

    sign_in_as(email: admin.email, password: "changeme")

    expect(page).to have_text("Demo data management")
    expect(page).to have_css('[data-testid="scenario-seed-reset-panel"]')
    expect(page).to have_text("Seed data resets")
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("fully_booked_day")

    within('[data-testid="scenario-seed-reset-baseline"]') do
      fill_in "Type baseline to continue", with: "baseline"
      click_button "Restore baseline"
    end

    expect(page).to have_text("Restored baseline demo scenario (Baseline Demo Estate).")
    expect(page).to have_text("baseline")

    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
  end
end
