require "rails_helper"

RSpec.describe "Admin demo scenarios", type: :system do
  def sign_in_as(admin)
    visit admin_demo_scenarios_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: "changeme"
    click_button "Sign in"
  end

  it "restores the baseline scenario from the admin area with the typed gate" do
    admin = FactoryBot.create(:admin, email: "steven@gotthekeys.com", password: "changeme", password_confirmation: "changeme")

    sign_in_as(admin)

    expect(page).to have_text("Demo data management")
    expect(page).to have_css('[data-testid="scenario-seed-reset-panel"]')
    expect(page).to have_text("Seed data resets")
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")

    within(:xpath, "//article[contains(., 'Fully Booked Day')]") do
      click_button "Apply"
    end

    expect(page).to have_text("Applied demo scenario Fully Booked Day.")
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("fully_booked_day")

    within('[data-testid="scenario-seed-reset-baseline"]') do
      fill_in "Type baseline to continue", with: "baseline"
      click_button "Run reset"
    end

    expect(page).to have_text("Restored baseline demo scenario (Baseline Demo Estate).")
    expect(page).to have_text("baseline")

    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
  end
end
