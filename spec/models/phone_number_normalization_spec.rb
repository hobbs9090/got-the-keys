require "rails_helper"

RSpec.describe "phone number normalisation" do
  it "normalises UK phone numbers on member action records" do
    property = FactoryBot.create(:property)
    rental_property = FactoryBot.create(:property, :for_rent)

    appointment = FactoryBot.build(
      :appointment,
      property: property,
      customer_phone: "07700 900123"
    )
    offer = FactoryBot.build(:offer, property: property, buyer_phone: "07700 900124")
    enquiry = FactoryBot.build(:enquiry, property: property, customer_phone: "+44 7700 900125")
    application = FactoryBot.build(:rental_application, property: rental_property, applicant_phone: "07700-900126")

    expect(appointment).to be_valid
    expect(offer).to be_valid
    expect(enquiry).to be_valid
    expect(application).to be_valid

    expect(appointment.customer_phone).to eq("+447700900123")
    expect(offer.buyer_phone).to eq("+447700900124")
    expect(enquiry.customer_phone).to eq("+447700900125")
    expect(application.applicant_phone).to eq("+447700900126")
  end

  it "leaves obvious garbage for model validations to reject" do
    offer = FactoryBot.build(:offer, buyer_phone: "not a phone")

    expect(offer).not_to be_valid
    expect(offer.errors[:buyer_phone]).to include(I18n.t("ui.validation.phone_number"))
  end
end
