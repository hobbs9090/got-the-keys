require "rails_helper"
require "nokogiri"

RSpec.describe "Header account details", type: :request do
  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  it "groups the guest register and sign-in buttons beside the language selector" do
    get root_path

    expect(response).to have_http_status(:ok)

    actions = parsed_html.at_css(".site-header__actions")
    expect(actions).to be_present

    action_classes = actions.element_children.map { |node| node["class"] }
    expect(action_classes.first).to include("language-dropdown")
    expect(action_classes.second).to include("site-header__guest-actions")

    guest_actions = parsed_html.at_css('[data-testid="guest-header-actions"]')
    expect(guest_actions).to be_present
    expect(guest_actions.css("a.button").map { |link| link.text.strip }).to eq(["Register", "Sign in"])
  end

  it "shows the signed-in admin details before the language selector and action buttons" do
    admin = FactoryBot.create(:admin, email: "header-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme")

    sign_in admin
    get root_path

    expect(response).to have_http_status(:ok)

    session_panel = parsed_html.at_css(".site-header__session")
    expect(session_panel).to be_present

    account_summary = session_panel.at_css('[data-testid="header-account-summary"]')
    expect(account_summary).to be_present
    expect(account_summary.at_css(".site-header__account-heading")).to be_present
    expect(account_summary.at_css(".site-header__account-detail")["title"]).to eq(admin.email)
    expect(account_summary.text).to include("Administrator")
    expect(account_summary.text).to include(admin.email)

    session_meta_classes = session_panel.at_css(".site-header__session-meta").element_children.map { |node| node["class"] }
    expect(session_meta_classes.first).to include("site-header__account")
    expect(session_meta_classes.second).to include("language-dropdown")

    button_texts = session_panel.css(".site-header__button-group a.button").map { |link| link.text.strip }
    expect(button_texts).to eq(["Dashboard", "Sign out"])
  end

  it "shows the signed-in member details before the language selector and action buttons" do
    user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")

    sign_in user
    get root_path

    expect(response).to have_http_status(:ok)

    session_panel = parsed_html.at_css(".site-header__session")
    expect(session_panel).to be_present

    account_summary = session_panel.at_css('[data-testid="header-account-summary"]')
    expect(account_summary).to be_present
    expect(account_summary.at_css(".site-header__account-heading")).to be_present
    expect(account_summary.at_css(".site-header__account-detail")["title"]).to eq(user.email)
    expect(account_summary.text).to include("Taylor Stone")
    expect(account_summary.text).to include(user.email)

    session_meta_classes = session_panel.at_css(".site-header__session-meta").element_children.map { |node| node["class"] }
    expect(session_meta_classes.first).to include("site-header__account")
    expect(session_meta_classes.second).to include("language-dropdown")

    button_texts = session_panel.css(".site-header__button-group a.button").map { |link| link.text.strip }
    expect(button_texts).to eq(["Add property", "Profile", "Sign out"])
  end
end
