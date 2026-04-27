require "rails_helper"

RSpec.describe "Api::V1::Properties", type: :request do
  describe "GET /api/v1/properties" do
    let!(:visible)   { create(:property, listing_state: "published", asking_price: 500_000) }
    let!(:other)     { create(:property, listing_state: "published", asking_price: 800_000) }
    let!(:draft)     { create(:property, :draft) }
    let!(:withdrawn) { create(:property, listing_state: "withdrawn") }

    it "returns only publicly visible properties" do
      get "/api/v1/properties", headers: api_json_headers
      expect(response).to have_http_status(:ok)
      ids = json_body["data"].map { |row| row["id"] }
      expect(ids).to include(visible.id, other.id)
      expect(ids).not_to include(draft.id, withdrawn.id)
    end

    it "returns pagination metadata" do
      get "/api/v1/properties", params: { page: 1, per_page: 1 }
      expect(json_body["meta"]).to include("page" => 1, "per_page" => 1)
      expect(json_body["meta"]["total_count"]).to eq(2)
      expect(json_body["data"].length).to eq(1)
    end

    it "filters by sale_status using the API enum keys" do
      rental = create(:property, :for_rent, listing_state: "published")
      get "/api/v1/properties", params: { sale_status: "for_rent" }
      ids = json_body["data"].map { |row| row["id"] }
      expect(ids).to include(rental.id)
      expect(ids).not_to include(visible.id, other.id)
    end

    it "caps per_page at 50" do
      get "/api/v1/properties", params: { per_page: 9999 }
      expect(json_body["meta"]["per_page"]).to eq(50)
    end

    it "sets a public Cache-Control for unauthenticated requests" do
      get "/api/v1/properties"
      expect(response.headers["Cache-Control"]).to include("public", "max-age=60")
    end

    it "marks saved properties when authenticated" do
      user = create(:user)
      create(:saved_property, user: user, property: visible)
      headers = api_auth_headers(user)
      get "/api/v1/properties", headers: headers
      row = json_body["data"].find { |r| r["id"] == visible.id }
      expect(row["saved_by_me"]).to be(true)
      other_row = json_body["data"].find { |r| r["id"] == other.id }
      expect(other_row["saved_by_me"]).to be(false)
    end

    it "leaves saved_by_me null for unauthenticated requests" do
      get "/api/v1/properties"
      expect(json_body["data"].first["saved_by_me"]).to be_nil
    end
  end

  describe "GET /api/v1/properties/:id" do
    let!(:property) { create(:property, listing_state: "published") }

    it "returns the detail payload" do
      get "/api/v1/properties/#{property.id}"
      expect(response).to have_http_status(:ok)
      expect(json_body["id"]).to eq(property.id)
      expect(json_body["description"]).to eq(property.property_description)
      expect(json_body["photos"]).to be_an(Array)
    end

    it "returns 410 Gone for withdrawn properties" do
      property.update!(listing_state: "withdrawn")
      get "/api/v1/properties/#{property.id}"
      expect(response).to have_http_status(:gone)
      expect(json_body.dig("error", "code")).to eq("gone")
    end

    it "returns 404 for draft properties" do
      property.update!(listing_state: "draft")
      get "/api/v1/properties/#{property.id}"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/properties/:id/availability" do
    let!(:property) { create(:property, listing_state: "published") }

    before do
      BookingConfiguration.current.update!(slot_duration_minutes: 60)
      create(:availability_window,
             property: property,
             starts_at: 2.days.from_now.beginning_of_day + 10.hours,
             ends_at:   2.days.from_now.beginning_of_day + 16.hours,
             kind: "open",
             capacity: 1)
    end

    it "returns slots and the booking configuration" do
      get "/api/v1/properties/#{property.id}/availability"
      expect(response).to have_http_status(:ok)
      body = json_body
      expect(body["slots"]).to be_an(Array)
      expect(body["configuration"]).to include("slot_duration_minutes", "lead_time_hours")
    end

    it "returns all slots within the booking window when no limit param is given" do
      get "/api/v1/properties/#{property.id}/availability"
      expect(response).to have_http_status(:ok)
      # The window has 6 hours at 1-hour intervals = 6 slots; none should be
      # cut short by a hard-coded default cap.
      expect(json_body["slots"].length).to eq(6)
    end

    it "caps results when ?limit= is provided" do
      get "/api/v1/properties/#{property.id}/availability", params: { limit: 2 }
      expect(response).to have_http_status(:ok)
      expect(json_body["slots"].length).to eq(2)
    end
  end
end
