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

    it "prefills contact details for signed-in users" do
      user = FactoryBot.create(
        :user,
        first_name: "Riya",
        last_name: "Patel",
        email: "riya.patel@example.com",
        mobile_number: "07700 930111"
      )
      sign_in(user)

      get new_property_enquiry_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(value="Riya Patel"))
      expect(response.body).to include(%(value="riya.patel@example.com"))
      expect(response.body).to include(%(value="07700 930111"))
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

      expect(response).to redirect_to(enquiry_path(Enquiry.last.lead_reference))
      expect(Enquiry.last.status).to eq("new")
    end
  end

  describe "GET /enquiries/:lead_reference" do
    let(:enquiry) { FactoryBot.create(:enquiry, property:) }

    it "redirects unauthenticated visitors to sign-in" do
      get enquiry_path(enquiry.lead_reference)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders the enquiry detail page for a signed-in user" do
      sign_in FactoryBot.create(:user)

      get enquiry_path(enquiry.lead_reference)

      expect(response).to have_http_status(:ok)
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
