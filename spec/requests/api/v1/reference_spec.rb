require "rails_helper"

RSpec.describe "Api::V1::Reference", type: :request do
  describe "GET /api/v1/reference/property_types" do
    it "returns the canonical list" do
      get "/api/v1/reference/property_types", headers: api_json_headers
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to include("House", "Flat")
      expect(response.headers["Cache-Control"]).to include("public")
    end
  end

  describe "GET /api/v1/reference/sale_statuses" do
    it "returns API-shape sale statuses" do
      get "/api/v1/reference/sale_statuses", headers: api_json_headers
      values = json_body["data"].map { |s| s["value"] }
      expect(values).to contain_exactly("for_sale", "for_rent")
    end
  end

  describe "GET /api/v1/reference/sort_options" do
    it "exposes the API sort enum" do
      get "/api/v1/reference/sort_options", headers: api_json_headers
      values = json_body["data"].map { |s| s["value"] }
      expect(values).to include("recommended", "newest", "price_asc", "price_desc")
    end
  end

  describe "GET /api/v1/reference/languages" do
    it "returns supported language codes" do
      get "/api/v1/reference/languages", headers: api_json_headers
      expect(response).to have_http_status(:ok)
      expect(json_body["data"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/reference/booking_window" do
    it "returns BookingConfiguration with ETag" do
      get "/api/v1/reference/booking_window", headers: api_json_headers
      expect(response).to have_http_status(:ok)
      expect(json_body).to include("slot_duration_minutes", "booking_window_days", "lead_time_hours")
      expect(response.headers["ETag"]).to be_present
    end

    it "returns 304 when If-None-Match matches" do
      get "/api/v1/reference/booking_window", headers: api_json_headers
      etag = response.headers["ETag"]
      get "/api/v1/reference/booking_window", headers: api_json_headers.merge("If-None-Match" => etag)
      expect(response).to have_http_status(:not_modified)
    end
  end
end
