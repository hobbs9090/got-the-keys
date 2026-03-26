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
    get admin_bookings_path

    expect(response).to have_http_status(:ok)

    brand_link = parsed_html.at_css(".admin-sidebar__brand-link")
    expect(brand_link).to be_present
    expect(brand_link["href"]).to eq(root_path)

    view_site_link = parsed_html.at_css(".admin-topbar__actions a.button.secondary.hollow.small")
    expect(view_site_link).to be_present
    expect(view_site_link.text.strip).to eq("View site")
    expect(view_site_link["href"]).to eq(root_path)

    sign_out_link = parsed_html.at_css(".admin-topbar__actions a.button.alert.hollow.small")
    expect(sign_out_link).to be_present
    expect(sign_out_link.text.strip).to eq("Sign out")
    expect(sign_out_link["href"]).to eq(destroy_admin_session_path)
  end
end
