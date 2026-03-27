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
    expect(response.body).to include("English")
    expect(response.body).to include("Deutsch")
    expect(response.body).to include("Français")
    expect(response.body).to include("Italiano")
    expect(response.body).to include("中文")
  end

  it "renders the member sign-in page" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect_shared_auth_card_layout
    expect(response.body).not_to include("marketing-wordmark--hero")
    expect(response.body).to include("Sign in")
  end

  it "renders the admin sign-in page" do
    get new_admin_session_path

    expect(response).to have_http_status(:ok)
    expect_shared_auth_card_layout
    expect(response.body).not_to include("marketing-wordmark--hero")
    expect(response.body).to include("Sign in as Administrator")
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
end
