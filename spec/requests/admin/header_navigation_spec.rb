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

    brand_link = parsed_html.at_css(".admin-sidebar__brand-link")
    expect(brand_link).to be_present
    expect(brand_link["href"]).to eq(root_path)

    view_site_link = parsed_html.at_css(".admin-topbar__actions a.button.secondary.hollow.admin-topbar__action")
    expect(view_site_link).to be_present
    expect(view_site_link.text.strip).to eq("View site")
    expect(view_site_link["href"]).to eq(root_path)

    admin_user = parsed_html.at_css(".admin-topbar__user")
    expect(admin_user).to be_present
    expect(admin_user.text.strip).to eq(admin.email)
    expect(admin_user["title"]).to eq(admin.email)

    lead_link = parsed_html.at_css('[data-testid="admin-enquiries-link"]')
    expect(lead_link).to be_present
    expect(lead_link["href"]).to eq(admin_enquiries_path)

    offers_link = parsed_html.at_css('[data-testid="admin-offers-link"]')
    expect(offers_link).to be_present
    expect(offers_link["href"]).to eq(admin_offers_path)

    applications_link = parsed_html.at_css('[data-testid="admin-rental-applications-link"]')
    expect(applications_link).to be_present
    expect(applications_link["href"]).to eq(admin_rental_applications_path)

    utility_nav = parsed_html.at_css('[data-testid="admin-nav-utility"]')
    expect(utility_nav).to be_present

    utility_texts = utility_nav.css("a").map { |link| link.text.strip }
    expect(utility_texts).to eq(["Demo Data", "QA Guide"])

    divider = parsed_html.at_css('[data-testid="admin-nav-divider"]')
    expect(divider).to be_present

    demo_data_link = utility_nav.at_css('[data-testid="admin-demo-data-link"]')
    expect(demo_data_link).to be_present
    expect(demo_data_link["href"]).to eq(admin_demo_scenarios_path)

    qa_link = utility_nav.at_css('[data-testid="admin-qa-link"]')
    expect(qa_link).to be_present
    expect(qa_link["href"]).to eq(admin_qa_path)

    sign_out_link = parsed_html.at_css(".admin-topbar__actions a.button.alert.hollow.admin-topbar__action")
    expect(sign_out_link).to be_present
    expect(sign_out_link.text.strip).to eq("Sign out")
    expect(sign_out_link["href"]).to eq(destroy_admin_session_path)
  end

  it "shows a friendly name for the curated local catalogue in the admin top bar" do
    BookingConfiguration.current.update!(active_demo_scenario_key: "custom_sevenoaks_westerham_catalogue")

    get admin_root_path

    expect(response).to have_http_status(:ok)

    active_scenario = parsed_html.at_css('[data-testid="active-demo-scenario"]')
    expect(active_scenario).to be_present
    expect(active_scenario.text.strip).to eq("Curated Sevenoaks and Westerham catalogue")
  end
end
