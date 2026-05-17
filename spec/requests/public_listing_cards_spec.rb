require "rails_helper"

RSpec.describe "Public listing cards", type: :request do
  let!(:seller) { FactoryBot.create(:user) }

  before do
    FactoryBot.create(:property, user: seller, address_line_1: "Sale CTA House")
    FactoryBot.create(:property, :for_rent, user: seller, address_line_1: "Rent CTA Flat")
  end

  it "redirects out-of-range page numbers to the last valid page" do
    [for_sale_index_path(page: 999), for_rent_index_path(page: 999), searches_path(page: 999)].each do |path|
      get path

      expect(response).to have_http_status(:moved_permanently), "expected 301 for #{path}"
      expect(response.location).to include("page=1"), "expected redirect to page=1 for #{path}"
    end
  end

  it "does not render booking CTAs on public catalogue cards" do
    [root_path, for_sale_index_path, for_rent_index_path, searches_path].each do |path|
      get path

      document = Nokogiri::HTML.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(document.at_css(%([data-testid="property-card"]))).to be_present
      expect(document.at_css(%([data-testid^="book-viewing-link-"]))).not_to be_present
      expect(document.at_css(%([data-testid^="book-viewing-sign-in-link-"]))).not_to be_present
    end
  end
end
