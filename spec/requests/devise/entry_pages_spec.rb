require "rails_helper"
require "nokogiri"

RSpec.describe "Devise entry pages", type: :request do
  def expect_shared_auth_card_layout
    document = Nokogiri::HTML.parse(response.body)
    header = document.at_css(".auth-form-card__header")
    title = header&.at_css(".auth-form-card__title")
    intro = header&.at_css(".auth-form-card__intro")
    header_children = header&.element_children || []

    expect(document.at_css(".auth-shell")).to be_present
    expect(document.at_css(".auth-panel.site-card")).to be_present
    expect(document.at_css(".auth-form-card.site-card")).to be_present
    expect(header).to be_present
    expect(title).to be_present
    expect(intro).to be_present
    expect(header_children.first.at_css(".auth-form-card__title")).to be_present
    expect(header_children[1]["class"]).to include("auth-form-card__intro")
    expect(document.at_css(".auth-form__actions")).to be_present
  end

  def switch_language(locale, return_to:)
    get new_language_path(language: locale.to_s, return_to: return_to),
        headers: { "HTTP_REFERER" => return_to }

    expect(response).to redirect_to(return_to)
  end

  it "renders the registration page" do
    get new_user_registration_path
    document = Nokogiri::HTML.parse(response.body)
    contact_fields = document.at_css(".auth-form__contact-fields")
    password_fields = document.at_css(".auth-form__password-fields")

    expect(response).to have_http_status(:ok)
    expect_shared_auth_card_layout
    expect(contact_fields).to be_present
    expect(contact_fields["class"]).to include("form-grid__full")
    expect(contact_fields.at_css('input[name="user[mobile_number]"]')).to be_present
    expect(contact_fields.at_css('input[type="email"]')).to be_present
    expect(password_fields).to be_present
    expect(password_fields["class"]).to include("form-grid__full")
    expect(password_fields.css('input[type="password"]').count).to eq(2)
    expect(response.body).not_to include("marketing-wordmark--hero")
    expect(response.body).to include("Register")
    expect(response.body).to include("Create your GotTheKeys account")
    expect(response.body).not_to include("Create your seller account")
    expect(response.body).to include("English")
    expect(response.body).to include("Deutsch")
    expect(response.body).to include("Français")
    expect(response.body).to include("Italiano")
    expect(response.body).to include("中文")
  end

  it "renders the member sign-in page" do
    get new_user_session_path
    document = Nokogiri::HTML.parse(response.body)

    expect(response).to have_http_status(:ok)
    expect_shared_auth_card_layout
    expect(response.body).not_to include("marketing-wordmark--hero")
    expect(response.body).to include("Sign in")
    expect(response.body).to include("Sign in to save this home")
    expect(document.at_css(".auth-panel").text.squish).to include("Sign in to manage your saved homes, viewings, offers, and any listings you're working on.")
    expect(response.body).not_to include("Pick up where you left off")
    expect(response.body).not_to include("manage your listings, confirm viewings")
    expect(response.body).not_to include("Your dashboard keeps your property details")
    expect(response.body).not_to include("seller dashboard")
    expect(document.at_css(%(a[href="#{new_user_password_path}"])).text.squish).to eq("Forgot your password?")
    expect(document.at_css(%(a[href="#{new_user_unlock_path}"])).text.squish).to eq("Didn't receive unlock instructions?")
    expect(document.at_css(%(a[href="#{new_admin_session_path}"])).text.squish).to eq("Sign in as administrator?")
  end

  it "renders the sign-in form with stable testid anchors" do
    get new_user_session_path

    document = Nokogiri::HTML.parse(response.body)

    expect(document.at_css(%([data-testid="sign-in-form"]))).to be_present
    expect(document.at_css(%([data-testid="sign-in-email"]))).to be_present
    expect(document.at_css(%([data-testid="sign-in-password"]))).to be_present
    expect(document.at_css(%([data-testid="sign-in-submit"]))).to be_present
  end

  it "renders the registration form with stable testid anchors" do
    get new_user_registration_path

    document = Nokogiri::HTML.parse(response.body)

    expect(document.at_css(%([data-testid="registration-form"]))).to be_present
    expect(document.at_css(%([data-testid="registration-first-name"]))).to be_present
    expect(document.at_css(%([data-testid="registration-last-name"]))).to be_present
    expect(document.at_css(%([data-testid="registration-mobile-number"]))).to be_present
    expect(document.at_css(%([data-testid="registration-email"]))).to be_present
    expect(document.at_css(%([data-testid="registration-password"]))).to be_present
    expect(document.at_css(%([data-testid="registration-password-confirmation"]))).to be_present
    terms_checkbox = document.at_css(%([data-testid="registration-terms"]))
    terms_link = document.at_css(%(label[for="user_terms_of_service"] a[href="/legal#terms-of-service"]))

    expect(terms_checkbox).to be_present
    expect(terms_link).to be_present
    expect(terms_link.text).to eq("Terms of Service")
    expect(document.at_css(%([data-testid="registration-submit"]))).to be_present
  end

  it "renders the admin sign-in page" do
    get new_admin_session_path
    document = Nokogiri::HTML.parse(response.body)

    expect(response).to have_http_status(:ok)
    expect_shared_auth_card_layout
    expect(response.body).not_to include("marketing-wordmark--hero")
    expect(response.body).to include("Sign in as Administrator")
    expect(response.body).to include("Manage the GotTheKeys workspace")
    expect(response.body).to include("Use your administrator credentials.")
    expect(response.body).to include("Use your administrator email address and password to continue.")
    expect(document.at_css(%(label[for="admin_email"])).text.squish).to eq("Email")
    auth_links = document.at_css(".auth-form-card__links")
    expect(auth_links.at_css(%(a[href="#{new_user_session_path}"])).text.squish).to eq("Sign in as member?")
    expect(auth_links.at_css(%(a[href="#{contact_us_path}"])).text.squish).to eq("Contact support for admin recovery")
    expect(response.body).not_to include("seller dashboard")
    expect(response.body).not_to include("Use the links below if you need to reset your password")
    expect(response.body).not_to include("Verification code or backup code")
  end

  it "keeps admin sign-in copy and links admin-specific" do
    get new_admin_session_path

    document = Nokogiri::HTML.parse(response.body)
    auth_panel = document.at_css(".auth-panel")
    form_card = document.at_css(".auth-form-card")
    auth_links = document.at_css(".auth-form-card__links")

    expect(auth_panel.at_css("h1").text.squish).to eq("Manage the GotTheKeys workspace")
    expect(auth_panel.text.squish).to include("Sign in to triage enquiries, manage listings, review bookings")
    expect(auth_panel.text.squish).to include("Use your administrator credentials.")
    expect(form_card.at_css(".auth-form-card__title").text.squish).to eq("Sign in as Administrator")
    expect(form_card.at_css(".auth-form-card__intro").text.squish).to eq("Use your administrator email address and password to continue.")
    expect(document.at_css(%(label[for="admin_email"])).text.squish).to eq("Email")
    expect(document.at_css(%(label[for="admin_email"])).text.squish).not_to eq("Username")
    expect(auth_links.at_css(%(a[href="#{new_user_session_path}"]))).to be_present
    expect(auth_links.at_css(%(a[href="#{contact_us_path}"]))).to be_present
    expect(auth_links.at_css(%(a[href="#{new_admin_session_path}"]))).to be_nil
    expect(response.body).not_to include("Pick up where you left off")
    expect(response.body).not_to include("seller dashboard")
    expect(response.body).not_to include("recovery links below")
  end

  it "renders the forgot password page" do
    get new_user_password_path

    expect(response).to have_http_status(:ok)
    expect_shared_auth_card_layout
    expect(response.body).not_to include("marketing-wordmark--hero")
    expect(response.body).to include("Forgot Password")
  end

  it "renders the resend unlock instructions page" do
    get new_user_unlock_path

    expect(response).to have_http_status(:ok)
    expect_shared_auth_card_layout
    expect(response.body).not_to include("marketing-wordmark--hero")
    expect(response.body).to include("Resend unlock instructions")
  end

  it "renders the guest auth pages in the selected non-English locale" do
    localized_pages = [
      {
        path: new_user_registration_path,
        keys: ["devise.views.registrations.new.title", "helpers.label.user.email", "devise.views.registrations.new.form_intro"]
      },
      {
        path: new_user_session_path,
        keys: ["devise.views.sessions.new.title", "helpers.label.user.password", "devise.views.sessions.new.form_intro"]
      },
      {
        path: new_admin_session_path,
        keys: ["devise.views.links.sign_in_as_admin", "helpers.label.admin.password", "devise.views.sessions.admin.form_intro"]
      },
      {
        path: new_user_password_path,
        keys: ["devise.views.passwords.new.title", "helpers.label.user.email", "devise.views.passwords.new.form_intro"]
      },
      {
        path: new_user_unlock_path,
        keys: ["devise.views.unlocks.new.title", "helpers.label.user.email", "devise.views.unlocks.new.form_intro"]
      }
    ]

    %i[de fr it].each do |locale|
      localized_pages.each do |page|
        switch_language(locale, return_to: page[:path])
        get page[:path]
        document = Nokogiri::HTML.parse(response.body)

        expect(response).to have_http_status(:ok)
        expect_shared_auth_card_layout
        expect(response.body).to include(%(lang="#{locale}"))

        page[:keys].each do |key|
          expect(document.text).to include(I18n.t(key, locale: locale))
        end
      end
    end
  end

  it "renders the account edit page in the signed-in user's language" do
    user = FactoryBot.create(:user, language: "de")

    sign_in user
    get edit_user_registration_path
    document = Nokogiri::HTML.parse(response.body)

    expect(response).to have_http_status(:ok)
    expect_shared_auth_card_layout
    expect(response.body).to include('lang="de"')
    expect(document.text).to include(I18n.t("devise.views.registrations.edit.title", locale: :de))
    expect(document.text).to include(I18n.t("helpers.label.user.current_password", locale: :de))
    expect(document.text).to include(I18n.t("devise.views.registrations.edit.cancel_action", locale: :de))
    expect(document.at_css('[data-testid="delete-account-trigger"]')).to be_present
    expect(document.at_css('#delete-account-modal[data-modal]')).to be_present
    expect(document.at_css('[data-testid="confirm-delete-account"]')).to be_present
    expect(document.at_css('[data-testid="confirm-delete-account"]')["disabled"]).to eq("disabled")
  end
end
