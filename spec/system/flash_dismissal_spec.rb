require "rails_helper"

RSpec.describe "Flash dismissal", type: :system, js: true do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to(Time.zone.local(2026, 3, 31, 14, 0)) { example.run }
  end

  it "auto-dismisses the admin sign-in notice after a short delay" do
    admin = FactoryBot.create(:admin, email: "dismiss-admin@gotthekeys.com", password: "changeme123", password_confirmation: "changeme123")

    visit new_admin_session_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: "changeme123"
    click_button "Sign in"

    expect(page).to have_css('[data-testid="flash-notice"]', text: "Signed in successfully as Admin.")
    expect(page).to have_no_css('[data-testid="flash-notice"]', wait: 7)
  end

  it "shows the timeout alert without rendering the raw timedout flag" do
    user = FactoryBot.create(:user, email: "timeout-flash-user@example.com", password: "changeme123", password_confirmation: "changeme123")

    visit new_user_session_path

    fill_in "user_email", with: user.email
    fill_in "user_password", with: "changeme123"
    click_button "Sign in"

    expect(page).to have_current_path(root_path, ignore_query: false)

    travel 31.minutes

    visit new_property_path

    expect(page).to have_current_path(new_user_session_path, ignore_query: false)
    expect(page).to have_css('[data-testid="flash-alert"]', text: "Your session expired, please sign in again to continue.")
    expect(page).to have_no_text("true")
    expect(page).to have_no_css('[data-testid="flash-timedout"]')
  end

  it "renders the timeout alert in the current page language" do
    user = FactoryBot.create(:user, email: "localized-timeout-flash-user@example.com", password: "changeme123", password_confirmation: "changeme123")

    visit new_language_path(language: "it", return_to: new_user_session_path)

    fill_in "user_email", with: user.email
    fill_in "user_password", with: "changeme123"
    click_button "Sign in"

    visit new_language_path(language: "en", return_to: root_path)

    travel 31.minutes

    visit new_property_path

    expect(page).to have_current_path(new_user_session_path, ignore_query: false)
    expect(page).to have_css('[data-testid="flash-alert"]', text: "Your session expired, please sign in again to continue.")
    expect(page).to have_no_text("La sessione è scaduta")
  end
end
