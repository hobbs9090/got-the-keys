require "rails_helper"

RSpec.describe "Api::V1::Properties::RentalApplications", type: :request do
  let!(:user)            { create(:user) }
  let!(:rental_property) { create(:property, :for_rent, listing_state: "published") }
  let(:move_in_date)     { (Date.current + 30.days).iso8601 }

  describe "POST /api/v1/properties/:property_id/rental_applications" do
    it "creates an application attributed to the authenticated user" do
      expect {
        post "/api/v1/properties/#{rental_property.id}/rental_applications",
             params: { move_in_date: move_in_date,
                        guarantor_available: true,
                        affordability_notes: "Salary £55k, 12 months in role." }.to_json,
             headers: api_auth_headers(user)
      }.to change(RentalApplication, :count).by(1)
      expect(response).to have_http_status(:created)
      application = RentalApplication.last
      expect(application.applicant_email).to eq(user.email)
      expect(application.guarantor_available).to eq(true)
      expect(json_body["public_reference"]).to eq(application.public_reference)
    end

    it "rejects applications on sale properties" do
      sale = create(:property, listing_state: "published")
      post "/api/v1/properties/#{sale.id}/rental_applications",
           params: { move_in_date: move_in_date }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "code")).to eq("validation_failed")
    end

    it "rejects applying to own property" do
      mine = create(:property, :for_rent, user: user, listing_state: "published")
      post "/api/v1/properties/#{mine.id}/rental_applications",
           params: { move_in_date: move_in_date }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      post "/api/v1/properties/#{rental_property.id}/rental_applications",
           params: { move_in_date: move_in_date }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "422s when move_in_date is unparseable" do
      post "/api/v1/properties/#{rental_property.id}/rental_applications",
           params: { move_in_date: "not-a-date" }.to_json,
           headers: api_auth_headers(user)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
