require "rails_helper"
require "nokogiri"

RSpec.describe "Admin header navigation" do
  let(:admin) { FactoryBot.create(:admin, email: "header-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  def child_testids(node)
    node.element_children.map { |child| child["data-testid"] || child.name }
  end

  it "defaults the public header button to the admin dashboard" do
    get root_path

    expect(response).to have_http_status(:ok)

    link = parsed_html.at_css('[data-testid="admin-bookings-entry-link"]')
    expect(link).to be_present
    expect(link.text.strip).to eq("Dashboard")
    expect(link["href"]).to eq(admin_root_path)
  end

  it "returns the admin to the last dashboard page they visited" do
    remembered_path = admin_bookings_path(view: "week", date: "2026-04-01")

    get remembered_path
    get root_path

    link = parsed_html.at_css('[data-testid="admin-bookings-entry-link"]')
    expect(link).to be_present
    expect(link["href"]).to eq(remembered_path)
  end

  it "keeps the admin layout action as view site" do
    get admin_enquiries_path

    expect(response).to have_http_status(:ok)

    topbar_wrap = parsed_html.at_css(".admin-topbar-wrap")
    expect(topbar_wrap).to be_present
    expect(response.body).to match(%r{/assets/admin-[^"]+\.css})
    expect(response.body).to match(%r{/assets/admin-[^"]+\.js})
    expect(response.body).not_to match(%r{/assets/public-[^"]+\.css})
    expect(parsed_html.at_css('meta[name="description"]')["content"]).to include("Manage property listings, customers, enquiries, bookings, and operations")
    expect(parsed_html.at_css('meta[name="robots"]')["content"]).to eq("noindex, nofollow")
    expect(parsed_html.at_css('link[rel="canonical"]')["href"]).to eq(admin_enquiries_url)
    expect(parsed_html.at_css('link[rel="preload"][as="style"][href*="/assets/admin-"]')).to be_present
    expect(parsed_html.at_css('link[rel="stylesheet"][href*="/assets/admin-"][media="print"][onload="this.media=\'all\'"]')).to be_present
    expect(parsed_html.at_css("noscript link[rel='stylesheet'][href*='/assets/admin-']")).to be_present
    expect(parsed_html.at_css("#admin-main-content[tabindex='-1']")).to be_present

    topbar = topbar_wrap.at_css(".admin-topbar")
    expect(topbar).to be_present
    expect(topbar.at_css(".admin-topbar__main")).to be_present
    expect(topbar.at_css('[data-testid="active-demo-scenario"]')).not_to be_present

    brand_link = parsed_html.at_css(".admin-sidebar__brand-link")
    expect(brand_link).to be_present
    expect(brand_link["href"]).to eq(root_path)
    expect(brand_link.at_css(".admin-sidebar__eyebrow")&.text&.strip).to eq(I18n.t("ui.site_header.eyebrow"))
    expect(brand_link.at_css(".marketing-wordmark--header")).to be_present

    session_panel = topbar.at_css(".admin-topbar__session")
    expect(session_panel).to be_present

    actions_top = session_panel.at_css(".site-header__actions-top")
    expect(actions_top).to be_present
    expect(child_testids(actions_top)).to eq(["admin-account-summary", "language-dropdown", "theme-toggle"])
    expect(actions_top.at_css('[data-testid="language-dropdown"]')).to be_present
    expect(actions_top.at_css('[data-testid="theme-toggle"]')).to be_present

    view_site_link = session_panel.at_css(".site-header__button-group a.button.primary.admin-topbar__action")
    expect(view_site_link).to be_present
    expect(view_site_link.text.strip).to eq("View site")
    expect(view_site_link["href"]).to eq(root_path)

    admin_user = session_panel.at_css('[data-testid="admin-account-summary"].site-header__account')
    expect(admin_user).to be_present
    expect(admin_user.at_css(".site-header__account-heading")).to be_present
    expect(admin_user.text).to include("Signed in")
    expect(admin_user.text).to include("Administrator")
    expect(admin_user.text).to include(admin.email)
    expect(admin_user.at_css(".site-header__account-detail")["title"]).to eq(admin.email)

    button_group = session_panel.at_css(".site-header__button-group")
    expect(button_group).to be_present
    expect(button_group.css("a.button").map { |link| link.text.strip }).to eq(["View site", "Sign out"])
    expect(button_group.css("a.button").map { |link| link["href"] }).to eq([root_path, destroy_admin_session_path])

    lead_link = parsed_html.at_css('[data-testid="admin-enquiries-link"]')
    expect(lead_link).to be_present
    expect(lead_link.text.strip).to eq(I18n.t("ui.admin.navigation.leads"))
    expect(lead_link["href"]).to eq(admin_enquiries_path)
    expect(lead_link["aria-current"]).to eq("page")

    offers_link = parsed_html.at_css('[data-testid="admin-offers-link"]')
    expect(offers_link).to be_present
    expect(offers_link.text.strip).to eq(I18n.t("ui.admin.navigation.sales"))
    expect(offers_link["href"]).to eq(admin_sales_path)

    applications_link = parsed_html.at_css('[data-testid="admin-rental-applications-link"]')
    expect(applications_link).to be_present
    expect(applications_link.text.strip).to eq(I18n.t("ui.admin.navigation.rentals"))
    expect(applications_link["href"]).to eq(admin_rentals_path)

    customers_link = parsed_html.at_css('[data-testid="admin-customers-link"]')
    expect(customers_link).to be_present
    expect(customers_link.text.strip).to eq(I18n.t("ui.admin.navigation.customers"))
    expect(customers_link["href"]).to eq(admin_customers_path)

    utility_nav = parsed_html.at_css('[data-testid="admin-nav-utility"]')
    expect(utility_nav).to be_present

    utility_title = parsed_html.at_css('[data-testid="admin-nav-utility-title"]')
    expect(utility_title).to be_present
    expect(utility_title.text.strip).to eq("QA Area")

    utility_texts = utility_nav.css("a").map { |link| link.text.strip }
    expect(utility_texts).to eq(["Demo Data", "Security", "QA Guide"])

    divider = parsed_html.at_css('[data-testid="admin-nav-divider"]')
    expect(divider).to be_present

    demo_data_link = utility_nav.at_css('[data-testid="admin-demo-data-link"]')
    expect(demo_data_link).to be_present
    expect(demo_data_link["href"]).to eq(admin_demo_scenarios_path)

    security_link = utility_nav.at_css('[data-testid="admin-security-link"]')
    expect(security_link).to be_present
    expect(security_link["href"]).to eq(admin_security_path)

    expect(utility_nav.at_css('[data-testid="admin-nav-utility-divider"]')).not_to be_present

    qa_link = utility_nav.at_css('[data-testid="admin-qa-link"]')
    expect(qa_link).to be_present
    expect(qa_link["href"]).to eq(admin_qa_path)

    sign_out_link = session_panel.at_css(".site-header__button-group a.button.alert.hollow.admin-topbar__action")
    expect(sign_out_link).to be_present
    expect(sign_out_link.text.strip).to eq("Sign out")
    expect(sign_out_link["href"]).to eq(destroy_admin_session_path)
  end

  it "keeps the admin top bar free of the active demo scenario label" do
    BookingConfiguration.current.update!(active_demo_scenario_key: "custom_sevenoaks_westerham_catalogue")

    get admin_root_path

    expect(response).to have_http_status(:ok)

    expect(parsed_html.at_css('[data-testid="active-demo-scenario"]')).not_to be_present
  end
end
