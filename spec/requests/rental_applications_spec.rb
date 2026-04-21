require "rails_helper"
require "nokogiri"

RSpec.describe "Rental applications", type: :request do
  let(:property) { FactoryBot.create(:property, :for_rent, address_line_1: "8 South Parade") }

  it "renders the public rental application form" do
    get new_property_rental_application_path(property)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Start a rental application for 8 South Parade")
    expect(response.body).not_to include("I already have a guarantor available")

    document = Nokogiri::HTML.parse(response.body)
    expect(document.at_css('[data-testid="rental-move-in-date"]')["value"]).to be_nil
  end

  it "prefills the rental application form for signed-in users" do
    user = FactoryBot.create(
      :user,
      first_name: "Zoe",
      last_name: "Bates",
      email: "zoe.bates@example.com",
      mobile_number: "07700 930099"
    )
    sign_in user

    get new_property_rental_application_path(property)

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    expect(document.at_css('[data-testid="rental-applicant-name"]')["value"]).to eq("Zoe Bates")
    expect(document.at_css('[data-testid="rental-applicant-email"]')["value"]).to eq("zoe.bates@example.com")
    expect(document.at_css('[data-testid="rental-applicant-phone"]')["value"]).to eq("07700 930099")
    expect(document.at_css('[data-testid="rental-move-in-date"]')["value"]).to be_nil
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
          affordability_notes: "Budget ready but may need a guarantor.",
          notes: "Could move in next month."
        }
      }
    end.to change(RentalApplication, :count).by(1)

    expect(response).to redirect_to(property_path(property))
    expect(RentalApplication.last.status).to eq("received")
  end

  it "rejects a rental application without a move-in date" do
    expect do
      post property_rental_applications_path(property), params: {
        rental_application: {
          applicant_name: "Priya Shah",
          applicant_email: "priya@example.com",
          applicant_phone: "07700 905200",
          move_in_date: "",
          guarantor_required: "1",
          affordability_notes: "Budget ready but may need a guarantor.",
          notes: "Could move in next month."
        }
      }
    end.not_to change(RentalApplication, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Preferred move-in date")
  end

  it "lets the signed-in applicant withdraw their own rental application" do
    applicant = FactoryBot.create(:user, email: "priya@example.com")
    rental_application = FactoryBot.create(:rental_application, property:, applicant_email: applicant.email, status: "received")
    sign_in applicant

    patch withdraw_property_rental_application_path(property, rental_application)

    expect(response).to redirect_to(mine_properties_path)
    expect(rental_application.reload.status).to eq("withdrawn")
  end

  it "does not let a signed-in user withdraw someone else's rental application" do
    intruder = FactoryBot.create(:user, email: "intruder@example.com")
    rental_application = FactoryBot.create(:rental_application, property:, applicant_email: "priya@example.com", status: "received")
    sign_in intruder

    patch withdraw_property_rental_application_path(property, rental_application)

    expect(response).to redirect_to(mine_properties_path)
    follow_redirect!
    expect(response.body).to include(I18n.t("ui.rental_applications.alerts.not_your_application"))
    expect(rental_application.reload.status).to eq("received")
  end
end
