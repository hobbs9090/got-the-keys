require "rails_helper"

RSpec.describe "Property enquiry flow", type: :system do
  it "lets a visitor send a property enquiry without booking a viewing" do
    property = FactoryBot.create(:property, address_line_1: "26 Hillside Walk")

    visit property_path(property)

    click_link "Send an enquiry"

    expect(page).to have_current_path(new_property_enquiry_path(property))

    within('[data-testid="property-enquiry-form"]') do
      fill_in "enquiry_customer_name", with: "Naomi Blake"
      fill_in "enquiry_customer_email", with: "naomi.blake@example.com"
      fill_in "enquiry_customer_phone", with: "07700 902500"
      select "Brochure request", from: "enquiry_source_type"
      fill_in "enquiry_message", with: "Please send the brochure and let me know whether the garden room is insulated for year-round use."

      expect do
        click_button "Send enquiry"
      end.to change(Enquiry, :count).by(1)
    end

    enquiry = Enquiry.order(:created_at).last

    expect(page).to have_current_path(property_path(property))
    expect(page).to have_text("Thanks. Your enquiry has been sent to the team.")
    expect(enquiry.lead_reference).to be_present
    expect(enquiry.source_type).to eq("brochure_request")
  end

  it "shows public brochure downloads but hides private files" do
    property = FactoryBot.create(:property, address_line_1: "31 Granville Road")
    FactoryBot.create(:property_document, property:, title: "Sales brochure", file_name: "granville-road-brochure.pdf", visibility: "public")
    FactoryBot.create(:property_document, :private_document, property:, title: "Compliance pack", file_name: "granville-road-compliance.pdf")

    visit property_path(property)

    expect(page).to have_css('[data-testid="property-documents-panel"]')
    expect(page).to have_text("Sales brochure")
    expect(page).not_to have_text("Compliance pack")
  end
end
