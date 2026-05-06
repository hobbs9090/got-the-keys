require "rails_helper"

RSpec.describe "Member confirmations" do
  let(:user) { FactoryBot.create(:user, email: "nina.hughes@example.com") }

  before do
    sign_in user
  end

  it "redirects submitted offers to a durable GTK reference page" do
    property = FactoryBot.create(:property, address_line_1: "19 Willow Road")

    post property_offers_path(property), params: {
      offer: {
        buyer_name: "Nina Hughes",
        buyer_email: "ignored@example.com",
        buyer_phone: "07700 905555",
        amount: "620000",
        chain_position: "Cash buyer",
        notes: "Flexible on completion."
      }
    }

    offer = Offer.last

    expect(offer.public_reference).to match(/\AGTK-OFR-[A-Z0-9]{8}\z/)
    expect(response).to redirect_to(offer_path(offer.public_reference))

    follow_redirect!

    expect(response.body).to include(offer.public_reference)
    expect(Nokogiri::HTML(response.body).at_css("h1").text.strip).to eq("Offer #{offer.public_reference}")
    expect(response.body).to include("Offer summary")
    expect(response.body).to include("£620,000")
  end

  it "redirects submitted enquiries to a durable GTK reference page" do
    property = FactoryBot.create(:property, address_line_1: "26 Hillside Walk")

    post property_enquiries_path(property), params: {
      enquiry: {
        customer_name: "Nina Hughes",
        customer_email: user.email,
        customer_phone: "07700 902500",
        source_type: "brochure_request",
        message: "Please send the brochure and confirm whether the garden room is insulated."
      }
    }

    enquiry = Enquiry.last

    expect(enquiry.lead_reference).to match(/\AGTK-ENQ-[A-Z0-9]{8}\z/)
    expect(response).to redirect_to(enquiry_path(enquiry.lead_reference))

    follow_redirect!

    expect(response.body).to include(enquiry.lead_reference)
    expect(Nokogiri::HTML(response.body).at_css("h1").text.strip).to eq("Enquiry #{enquiry.lead_reference}")
    expect(response.body).to include("Enquiry summary")
    expect(response.body).to include("Brochure request")
  end

  it "redirects submitted rental applications to a durable GTK reference page" do
    property = FactoryBot.create(:property, :for_rent, address_line_1: "4 Station Court")

    post property_rental_applications_path(property), params: {
      rental_application: {
        applicant_name: "Nina Hughes",
        applicant_email: "ignored@example.com",
        applicant_phone: "07700 905777",
        move_in_date: (Date.current + 21.days).iso8601,
        affordability_notes: "Permanent employment and ready to provide referencing documents.",
        notes: "Would like to move quickly."
      }
    }

    application = RentalApplication.last

    expect(application.public_reference).to match(/\AGTK-RNT-[A-Z0-9]{8}\z/)
    expect(response).to redirect_to(rental_application_path(application.public_reference))

    follow_redirect!

    expect(response.body).to include(application.public_reference)
    expect(Nokogiri::HTML(response.body).at_css("h1").text.strip).to eq("Rental application #{application.public_reference}")
    expect(response.body).to include("Application summary")
    expect(response.body).to include("Permanent employment")
  end

  it "surfaces existing member actions on the property page" do
    property = FactoryBot.create(:property, address_line_1: "33 The Avenue")
    offer = FactoryBot.create(:offer, property:, buyer_email: user.email, amount: 820_000)
    enquiry = FactoryBot.create(:enquiry, property:, customer_email: user.email, source_type: "general_enquiry")

    get property_path(property)

    document = Nokogiri::HTML(response.body)

    expect(document.at_css('[data-testid="view-existing-offer-link"]')["href"]).to eq(offer_path(offer.public_reference))
    expect(document.at_css('[data-testid="view-existing-enquiry-link"]')["href"]).to eq(enquiry_path(enquiry.lead_reference))
    expect(response.body).to include("You have a pending offer of £820,000")
    expect(response.body).not_to include(new_property_offer_path(property))
  end
end
