require "rails_helper"
require "nokogiri"

RSpec.describe "Admin dashboard", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "dashboard-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  it "renders the bookings shortcuts as a button group" do
    get admin_root_path

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    status_grid = document.at_css('[data-testid="admin-dashboard-status-grid"]')
    quick_links = document.css(".admin-dashboard__quick-links a")
    status_cards = document.css('[data-testid^="admin-status-card-"]:not([data-testid^="admin-status-card-link-"])')

    expect(status_grid).to be_present
    expect(status_cards.map { |card| card.at_css(".admin-dashboard__status-label")&.text&.strip }).to eq(
      ["Properties", "Require review", "Upcoming appointments", "Pending actions", "Offers", "Customers", "Open leads"]
    )

    status_cards.each do |card|
      expect(card["class"]).to include("admin-dashboard__status-card")
      expect(card.at_css(".admin-dashboard__status-value")).to be_present
    end

    expect(document.at_css('[data-testid="admin-status-card-link-properties"]')["href"]).to eq(admin_properties_path)
    expect(document.at_css('[data-testid="admin-status-card-link-properties_requiring_review"]')["href"]).to eq(admin_properties_path(listing_state: "review_pending"))
    expect(document.at_css('[data-testid="admin-status-card-link-upcoming_appointments"]')["href"]).to eq(admin_appointments_path(view: "agenda"))
    expect(document.at_css('[data-testid="admin-status-card-link-pending_actions"]')["href"]).to eq(admin_appointments_path(view: "agenda", queue: "pending_action"))
    expect(document.at_css('[data-testid="admin-status-card-link-offers"]')["href"]).to eq(admin_sales_path)
    expect(document.at_css('[data-testid="admin-status-card-link-customers"]')["href"]).to eq(admin_customers_path)
    expect(document.at_css('[data-testid="admin-status-card-link-open_leads"]')["href"]).to eq(admin_enquiries_path)

    expect(quick_links.map { |link| link.text.strip }).to eq(["All bookings", "Pending action", "This week"])
    expect(quick_links.first["class"]).to include("button")
    expect(quick_links.first["class"]).to include("primary")

    quick_links.drop(1).each do |link|
      expect(link["class"]).to include("button")
      expect(link["class"]).to include("secondary")
      expect(link["class"]).to include("hollow")
    end
  end

  it "serves metrics from cache on repeated requests" do
    get admin_root_path
    expect(response).to have_http_status(:ok)

    expect(Rails.cache).to receive(:fetch).with("admin/dashboard/metrics", expires_in: 5.minutes).and_call_original

    get admin_root_path
    expect(response).to have_http_status(:ok)
  end

  it "uses compact status pills in the recent activity table" do
    property = FactoryBot.create(:property)
    appointment = FactoryBot.create(:appointment, property:, status: "pending")

    get admin_root_path

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    row = document.css(".admin-list__item").find { |candidate| candidate.text.include?(appointment.public_reference) }
    status_badge = row.css("span").last

    expect(row).to be_present
    expect(row.at_css("p")&.text.to_s).to include(appointment.customer_name, appointment.property.address_line_1)
    expect(status_badge["class"]).to include("badge")
    expect(status_badge["class"]).to include("admin-bookings-row__pill")
  end
end
