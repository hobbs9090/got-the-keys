require "rails_helper"

RSpec.describe "Rental applications", type: :request do
  let(:property) { FactoryBot.create(:property, :for_rent, address_line_1: "8 South Parade") }

  it "renders the public rental application form" do
    get new_property_rental_application_path(property)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Start a rental application for 8 South Parade")
  end

  it "creates a public rental application" do
    expect do
      post property_rental_applications_path(property), params: {
        rental_application: {
          applicant_name: "Priya Shah",
          applicant_email: "priya@example.com",
          applicant_phone: "07700 905200",
          move_in_date: Date.current + 21.days,
          guarantor_required: "1",
          guarantor_available: "0",
          affordability_notes: "Budget ready but may need a guarantor.",
          notes: "Could move in next month."
        }
      }
    end.to change(RentalApplication, :count).by(1)

    expect(response).to redirect_to(property_path(property))
    expect(RentalApplication.last.status).to eq("received")
  end
end
