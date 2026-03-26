require "rails_helper"

RSpec.describe "Enquiries", type: :request do
  let(:property) { FactoryBot.create(:property, address_line_1: "41 Oakfield Road") }

  describe "GET /properties/:property_id/enquiries/new" do
    it "renders the enquiry form for a public listing" do
      get new_property_enquiry_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ask about 41 Oakfield Road")
      expect(response.body).to include(%(data-testid="property-enquiry-form"))
    end
  end

  describe "POST /properties/:property_id/enquiries" do
    it "creates a lead and enqueues notifications" do
      expect do
        post property_enquiries_path(property), params: {
          enquiry: {
            customer_name: "Maya Singh",
            customer_email: "maya@example.com",
            customer_phone: "07700 901234",
            source_type: "brochure_request",
            message: "Please send the brochure and confirm whether the loft room has planning sign-off."
          }
        }
      end.to change(Enquiry, :count).by(1)
        .and have_enqueued_job(EnquiryNotificationJob)

      expect(response).to redirect_to(property_path(property))
      expect(Enquiry.last.status).to eq("new")
    end
  end

  describe "GET /properties/:id" do
    it "shows recent lead activity to the seller" do
      sign_in property.user
      FactoryBot.create(:enquiry, property:, customer_name: "Anna Webb", source_type: "brochure_request")

      get property_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-testid="seller-recent-enquiries"))
      expect(response.body).to include("Anna Webb")
    end
  end
end
