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
    quick_links = document.css(".admin-dashboard__quick-links a")

    expect(quick_links.map { |link| link.text.strip }).to eq(["All bookings", "Pending action", "This week"])
    expect(quick_links.first["class"]).to include("button")
    expect(quick_links.first["class"]).to include("primary")

    quick_links.drop(1).each do |link|
      expect(link["class"]).to include("button")
      expect(link["class"]).to include("secondary")
      expect(link["class"]).to include("hollow")
    end
  end
end
