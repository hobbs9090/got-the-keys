require "rails_helper"

RSpec.describe "Flash dismissal", type: :system, js: true do
  it "auto-dismisses the admin sign-in notice after a short delay" do
    admin = FactoryBot.create(:admin, email: "dismiss-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme")

    visit new_admin_session_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: "changeme"
    click_button "Sign in"

    expect(page).to have_css('[data-testid="flash-notice"]', text: "Signed in successfully as Admin.")
    expect(page).to have_no_css('[data-testid="flash-notice"]', wait: 7)
  end
end
