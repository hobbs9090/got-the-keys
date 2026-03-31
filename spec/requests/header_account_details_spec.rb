require "rails_helper"
require "nokogiri"

RSpec.describe "Header account details", type: :request do
  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  def body_classes
    parsed_html.at_css("body")["class"].split
  end

  def child_testids(node)
    node.element_children.map { |child| child["data-testid"] || child.name }
  end

  def link_texts(selector)
    parsed_html.css(selector).map { |link| link.text.strip }
  end

  def link_hrefs(selector)
    parsed_html.css(selector).map { |link| link["href"] }
  end

  it "groups the guest register and sign-in buttons beside the language selector" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(body_classes).to include("site-shell", "welcome")
    expect(body_classes).not_to include("welcome--from-admin")
    expect(parsed_html.at_css("html")["data-theme-preference"]).to eq("system")
    expect(response.body).to include("gotthekeys-theme-preference")
    expect(response.body).to include("prefers-color-scheme: dark")
    expect(parsed_html.at_css('a.skip-link')["href"]).to eq("#main-content")
    expect(parsed_html.at_css("main#main-content[tabindex='-1']")).to be_present

    header = parsed_html.at_css('[data-testid="site-header"]')
    expect(header).to be_present

    home_link = header.at_css('[data-testid="home-link"]')
    expect(home_link).to be_present
    expect(home_link["href"]).to eq(root_path)
    expect(home_link.at_css(".site-brand__eyebrow")&.text&.strip).to eq(I18n.t("ui.site_header.eyebrow"))
    expect(home_link.at_css(".marketing-wordmark--header")).to be_present

    expect(link_texts('[data-testid="site-nav"] a')).to eq(["For Sale", "For Rent", "Search"])
    expect(link_hrefs('[data-testid="site-nav"] a')).to eq([for_sale_index_path, for_rent_index_path, searches_path])

    actions = parsed_html.at_css(".site-header__actions")
    expect(actions).to be_present

    actions_top = actions.at_css(".site-header__actions-top")
    expect(actions_top).to be_present
    expect(child_testids(actions_top)).to eq(["language-dropdown", "theme-toggle"])
    expect(actions_top.at_css('[data-testid="language-dropdown"]')).to be_present
    theme_toggle = actions_top.at_css('[data-testid="theme-toggle"]')
    expect(theme_toggle).to be_present
    expect(theme_toggle.at_css(".theme-toggle__summary-code")&.text&.strip).to eq("System")
    expect(theme_toggle.css(".theme-toggle__option").map { |option| option.text.strip }).to eq(["System", "Light", "Dark"])
    expect(actions_top.at_css('[data-testid="header-account-summary"]')).not_to be_present

    actions_row = actions.at_css(".site-header__actions-row")
    expect(actions_row).to be_present

    guest_actions = parsed_html.at_css('[data-testid="guest-header-actions"]')
    expect(guest_actions).to be_present
    expect(link_texts('[data-testid="guest-header-actions"] a.button')).to eq(["Register", "Sign in"])
    expect(link_hrefs('[data-testid="guest-header-actions"] a.button')).to eq([new_user_registration_path, new_user_session_path])
  end

  it "marks the active public navigation item with aria-current" do
    get searches_path

    expect(response).to have_http_status(:ok)

    active_link = parsed_html.at_css('[data-testid="site-nav"] a[aria-current="page"]')
    expect(active_link).to be_present
    expect(active_link.text.strip).to eq("Search")
    expect(active_link["href"]).to eq(searches_path)
  end

  it "defaults the searches listing type filter to all properties" do
    get searches_path

    expect(response).to have_http_status(:ok)

    search_filter = parsed_html.at_css('select[name="sale_status"]')
    first_option = search_filter.at_css("option:first-child")

    expect(search_filter).to be_present
    expect(first_option["value"]).to eq("")
    expect(first_option.text.strip).to eq(I18n.t("ui.properties.filters.all_properties"))
    expect(search_filter.at_css("option[selected]")).not_to be_present
  end

  it "marks the homepage shell when arriving from the admin area" do
    get root_path, headers: { "HTTP_REFERER" => admin_root_url }

    expect(response).to have_http_status(:ok)
    expect(body_classes).to include("welcome--from-admin")
  end

  it "does not mark the homepage shell when arriving from a non-admin page" do
    get root_path, headers: { "HTTP_REFERER" => searches_url }

    expect(response).to have_http_status(:ok)
    expect(body_classes).not_to include("welcome--from-admin")
  end

  it "ignores malformed referrers when deciding the homepage shell state" do
    get root_path, headers: { "HTTP_REFERER" => "not a valid url" }

    expect(response).to have_http_status(:ok)
    expect(body_classes).not_to include("welcome--from-admin")
  end

  it "shows a compact admin header on the homepage" do
    admin = FactoryBot.create(:admin, email: "header-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme")

    sign_in admin
    get root_path

    expect(response).to have_http_status(:ok)
    expect(body_classes).to include("site-shell", "welcome")
    expect(body_classes).not_to include("welcome--from-admin")

    actions_top = parsed_html.at_css(".site-header__actions-top")
    expect(actions_top).to be_present
    expect(child_testids(actions_top)).to eq(["header-account-summary", "language-dropdown", "theme-toggle"])
    expect(actions_top.at_css('[data-testid="language-dropdown"]')).to be_present
    expect(actions_top.at_css('[data-testid="theme-toggle"]')).to be_present

    account_summary = actions_top.at_css('[data-testid="header-account-summary"]')
    expect(account_summary).to be_present
    expect(account_summary.at_css(".site-header__account-heading")).to be_present
    expect(account_summary.at_css(".site-header__account-detail")["title"]).to eq(admin.email)
    expect(account_summary.text).to include("Administrator")
    expect(account_summary.text).to include(admin.email)

    button_group = parsed_html.at_css(".site-header__actions-row .site-header__button-group")
    expect(button_group).to be_present

    expect(link_texts(".site-header__actions-row .site-header__button-group a.button")).to eq(["Dashboard", "Sign out"])
    expect(link_hrefs(".site-header__actions-row .site-header__button-group a.button")).to eq([admin_root_path, destroy_admin_session_path])
  end

  it "shows the signed-in member details before the language selector and action buttons" do
    user = FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com")

    sign_in user
    get root_path

    expect(response).to have_http_status(:ok)
    actions_top = parsed_html.at_css(".site-header__actions-top")
    expect(actions_top).to be_present
    expect(child_testids(actions_top)).to eq(["header-account-summary", "language-dropdown", "theme-toggle"])
    expect(actions_top.at_css('[data-testid="language-dropdown"]')).to be_present
    expect(actions_top.at_css('[data-testid="theme-toggle"]')).to be_present

    account_summary = actions_top.at_css('[data-testid="header-account-summary"]')
    expect(account_summary).to be_present
    expect(account_summary.at_css(".site-header__account-heading")).to be_present
    expect(account_summary.at_css(".site-header__account-detail")["title"]).to eq(user.email)
    expect(account_summary.text).to include("Taylor Stone")
    expect(account_summary.text).to include(user.email)

    expect(link_texts(".site-header__actions-row .site-header__button-group a.button")).to eq(["My listings", "Add property", "Profile", "Sign out"])
    expect(link_hrefs(".site-header__actions-row .site-header__button-group a.button")).to eq([mine_properties_path, new_property_path, edit_user_registration_path, destroy_user_session_path])
  end
end
