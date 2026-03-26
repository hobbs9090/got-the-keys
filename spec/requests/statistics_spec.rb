require "rails_helper"
require "nokogiri"

RSpec.describe "Statistics" do
  let(:admin) { FactoryBot.create(:admin, email: "stats-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  it "renders chart placeholders for the bundled statistics runtime" do
    get "/statistics"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("charts.js")

    document = Nokogiri::HTML.parse(response.body)
    charts = document.css("[data-statistics-chart]")

    expect(charts.count).to eq(4)
    expect(charts.map { |chart| chart["data-chart-type"] }).to contain_exactly("pie", "bar", "geo", "pie")
    expect(charts.map { |chart| chart["id"] }).to include("english_vs_chinese_chart", "property_size_chart", "activity_chart", "rent_vs_sale_chart")
  end
end
