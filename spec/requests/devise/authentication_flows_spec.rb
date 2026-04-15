require "rails_helper"
require "nokogiri"

RSpec.describe "Devise authentication flows", type: :request do
  def document
    Nokogiri::HTML.parse(response.body)
  end

  def flash_text
    document.at_css("[data-testid='flash-stack']")&.text&.squish
  end

  def page_text
    document.text.squish
  end

  def registration_params(overrides = {})
    {
      first_name: "Jamie",
      last_name: "Rivera",
      mobile_number: "07595 123456",
      language: "en",
      terms_of_service: "1",
      email: "jamie.rivera@example.com",
      password: "changeme",
      password_confirmation: "changeme"
    }.merge(overrides)
  end

  describe "sign in" do
    it "signs a user in with valid credentials and shows the standard notice" do
      user = FactoryBot.create(:user, email: "auth-flow-user@example.com", password: "changeme", password_confirmation: "changeme")

      post user_session_path, params: { user: { email: user.email, password: "changeme" } }

      expect(response).to redirect_to(root_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash_text).to include(I18n.t("devise.sessions.signed_in"))
    end

    it "re-renders the form when the credentials are invalid" do
      user = FactoryBot.create(:user, email: "auth-flow-invalid@example.com", password: "changeme", password_confirmation: "changeme")

      post user_session_path, params: { user: { email: user.email, password: "wrongpass" } }

      expect(response).not_to be_redirect
      expect(response.body).to include(I18n.t("devise.failure.invalid", authentication_keys: "Email"))
    end

    it "blocks a locked user from signing in" do
      user = FactoryBot.create(:user, email: "auth-flow-locked@example.com", password: "changeme", password_confirmation: "changeme")
      user.lock_access!

      post user_session_path, params: { user: { email: user.email, password: "changeme" } }

      expect(response).not_to be_redirect
      expect(response.body).to include(I18n.t("devise.failure.locked"))
    end
  end

  describe "registration" do
    it "creates a member account and signs the new user in" do
      expect do
        post user_registration_path, params: { user: registration_params }
      end.to change(User, :count).by(1)

      created_user = User.order(:id).last

      expect(response).to redirect_to(root_path)
      expect(created_user.email).to eq("jamie.rivera@example.com")
      expect(created_user.first_name).to eq("Jamie")
      expect(created_user.last_name).to eq("Rivera")
      expect(created_user.mobile_number).to eq("07595 123456")
      expect(created_user.language).to eq("en")

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash_text).to include(I18n.t("devise.registrations.signed_up"))
    end

    it "shows validation feedback when the registration is invalid" do
      expect do
        post user_registration_path, params: {
          user: registration_params(
            terms_of_service: "0",
            password_confirmation: "different"
          )
        }
      end.not_to change(User, :count)

      expect(response).not_to be_redirect
      expect(page_text).to include(I18n.t("errors.messages.accepted"))
      expect(page_text).to include(I18n.t("errors.messages.confirmation", attribute: "Password"))
    end
  end

  describe "password reset" do
    before do
      ActionMailer::Base.deliveries.clear
    end

    it "sends reset instructions to an existing user" do
      user = FactoryBot.create(:user, email: "auth-flow-reset@example.com")

      expect do
        post user_password_path, params: { user: { email: user.email } }
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to redirect_to(new_user_session_path)
      expect(ActionMailer::Base.deliveries.last.to).to eq([ user.email ])

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash_text).to include(I18n.t("devise.passwords.send_instructions"))
    end

    it "updates the password from a valid reset token and accepts the new password" do
      user = FactoryBot.create(:user, email: "auth-flow-reset-update@example.com", password: "changeme", password_confirmation: "changeme")
      raw_token = user.send_reset_password_instructions

      put user_password_path, params: {
        user: {
          reset_password_token: raw_token,
          password: "newpassword",
          password_confirmation: "newpassword"
        }
      }

      expect(response).to redirect_to(new_user_session_path)
      expect(user.reload.valid_password?("newpassword")).to be(true)
      expect(user.valid_password?("changeme")).to be(false)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash_text).to include(I18n.t("devise.passwords.updated_not_active"))

      delete destroy_user_session_path
      post user_session_path, params: { user: { email: user.email, password: "newpassword" } }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "unlock" do
    before do
      ActionMailer::Base.deliveries.clear
    end

    it "emails unlock instructions for a locked account" do
      user = FactoryBot.create(:user, email: "auth-flow-unlock@example.com")
      user.lock_access!

      expect do
        post user_unlock_path, params: { user: { email: user.email } }
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to redirect_to(new_user_session_path)
      expect(ActionMailer::Base.deliveries.last.to).to eq([ user.email ])

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash_text).to include(I18n.t("devise.unlocks.send_instructions"))
    end

    it "unlocks the account from a valid token and allows sign in again" do
      user = FactoryBot.create(:user, email: "auth-flow-unlock-complete@example.com", password: "changeme", password_confirmation: "changeme")
      user.lock_access!
      raw_token = user.send_unlock_instructions

      get user_unlock_path, params: { unlock_token: raw_token }

      expect(response).to redirect_to(new_user_session_path)
      expect(user.reload.access_locked?).to be(false)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(flash_text).to include(I18n.t("devise.unlocks.unlocked"))

      delete destroy_user_session_path
      post user_session_path, params: { user: { email: user.email, password: "changeme" } }

      expect(response).to redirect_to(root_path)
    end
  end
end
