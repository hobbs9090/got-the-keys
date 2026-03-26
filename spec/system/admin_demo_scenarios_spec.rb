require "rails_helper"

RSpec.describe "Admin demo scenarios", type: :system do
  def sign_in_as(admin)
    visit admin_demo_scenarios_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: "changeme"
    click_button "Sign in"
  end

  it "restores the baseline scenario from the admin area" do
    admin = FactoryBot.create(:admin, email: "steven@gotthekeys.com", password: "changeme", password_confirmation: "changeme")

    sign_in_as(admin)

    expect(page).to have_text("Demo data management")
    expect(page).to have_css('[data-testid="active-demo-scenario"]', text: "Baseline")
    expect(page).to have_css('[data-testid="scenario-quick-reset-panel"]')

    within(:xpath, "//article[contains(., 'Fully Booked Day')]") do
      click_button "Apply"
    end

    expect(page).to have_text("Applied demo scenario Fully Booked Day.")
    expect(page).to have_css('[data-testid="active-demo-scenario"]', text: "Fully booked day")

    click_button "Restore baseline"

    expect(page).to have_text("Restored baseline demo scenario (Baseline Demo Estate).")
    expect(page).to have_css('[data-testid="active-demo-scenario"]', text: "Baseline")
    expect(page).to have_text("baseline")

    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
  end
end
