require "rails_helper"

RSpec.describe "Api::V1::RentalApplications", type: :request do
  let!(:user)            { create(:user) }
  let!(:rental_property) { create(:property, :for_rent, listing_state: "published") }

  def my_application(*traits, **overrides)
    create(:rental_application, *traits, property: rental_property, applicant_email: user.email, **overrides)
  end

  describe "GET /api/v1/rental_applications" do
    it "returns only the user's applications" do
      mine    = my_application
      _theirs = create(:rental_application, property: rental_property)

      get "/api/v1/rental_applications", headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      references = json_body["data"].map { |a| a["public_reference"] }
      expect(references).to contain_exactly(mine.public_reference)
    end

    it "filters by status" do
      received = my_application
      _approved = my_application(:approved)

      get "/api/v1/rental_applications", params: { status: "received" }, headers: api_auth_headers(user)
      references = json_body["data"].map { |a| a["public_reference"] }
      expect(references).to contain_exactly(received.public_reference)
    end

    it "requires authentication" do
      get "/api/v1/rental_applications", headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/rental_applications/:public_reference" do
    it "returns the application" do
      application = my_application
      get "/api/v1/rental_applications/#{application.public_reference}", headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_body["public_reference"]).to eq(application.public_reference)
    end

    it "404s for someone else's application" do
      other = create(:rental_application, property: rental_property)
      get "/api/v1/rental_applications/#{other.public_reference}", headers: api_auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/rental_applications/:public_reference/withdraw" do
    it "withdraws a received application" do
      application = my_application
      patch "/api/v1/rental_applications/#{application.public_reference}/withdraw",
            params: {}.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(application.reload.status).to eq("withdrawn")
    end

    it "409s when application is rejected" do
      application = my_application(:rejected)
      patch "/api/v1/rental_applications/#{application.public_reference}/withdraw",
            params: {}.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:conflict)
    end
  end
end
