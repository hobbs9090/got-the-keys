require "rails_helper"

RSpec.describe "User registration", type: :system, js: true do
  def dismiss_cookie_banner
    click_button "Reject non-essential" if page.has_button?("Reject non-essential", wait: 1)
  end

  def sign_in_as_user(user, password: "changeme")
    visit new_user_session_path

    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button "Sign in"
  end

  it "does not leave an overlay blocking the page after sign up" do
    visit new_user_registration_path

    dismiss_cookie_banner

    unique_email = "signup-#{SecureRandom.hex(4)}@example.com"

    fill_in "user_first_name", with: "Test"
    fill_in "user_last_name", with: "User"
    fill_in "user_mobile_number", with: "07595 123456"
    fill_in "user_email", with: unique_email
    select "English", from: "user_language"
    fill_in "user_password", with: "changeme"
    fill_in "user_password_confirmation", with: "changeme"
    check "user_terms_of_service"

    click_button "Register"

    expect(page).to have_current_path(root_path, wait: 10)
    expect(page).to have_no_css("body.site-modal-open", visible: false)
    expect(page).to have_no_css('[data-modal][aria-hidden="false"]', visible: false)

    page.find("a", text: "Search").click
    expect(page).to have_current_path(searches_path, wait: 5)
  end

  it "uses a checkbox-gated modal to confirm account deletion" do
    user = FactoryBot.create(:user, password: "changeme", password_confirmation: "changeme")

    sign_in_as_user(user)
    dismiss_cookie_banner
    visit edit_user_registration_path

    click_button "Delete this account"

    expect(page).to have_css("#delete-account-modal[aria-hidden='false']", visible: true)
    expect(page).to have_css("body.site-modal-open", visible: false)
    expect(page).to have_css('[data-testid="confirm-delete-account"][disabled]')

    check "I understand this permanently deletes my account and cannot be undone."

    expect(page).to have_button("Delete account", disabled: false)
  end

end
