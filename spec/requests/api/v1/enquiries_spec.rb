require "rails_helper"

RSpec.describe "Api::V1::Enquiries", type: :request do
  let!(:user)     { create(:user) }
  let!(:property) { create(:property, listing_state: "published") }

  def my_enquiry(*traits, **overrides)
    create(:enquiry, *traits, property: property, customer_email: user.email, **overrides)
  end

  describe "GET /api/v1/enquiries" do
    it "returns only the user's enquiries" do
      mine = my_enquiry
      _theirs = create(:enquiry, property: property)

      get "/api/v1/enquiries", headers: api_auth_headers(user)

      expect(response).to have_http_status(:ok)
      references = json_body["data"].map { |enquiry| enquiry["lead_reference"] }
      expect(references).to contain_exactly(mine.lead_reference)
    end

    it "filters by status" do
      new_enquiry = my_enquiry
      _contacted = my_enquiry(:contacted)

      get "/api/v1/enquiries", params: { status: "new" }, headers: api_auth_headers(user)

      references = json_body["data"].map { |enquiry| enquiry["lead_reference"] }
      expect(references).to contain_exactly(new_enquiry.lead_reference)
    end

    it "requires authentication" do
      get "/api/v1/enquiries", headers: api_json_headers

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
