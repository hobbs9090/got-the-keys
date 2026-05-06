require "rails_helper"

RSpec.describe Enquiry do
  it "requires an email address or phone number" do
    enquiry = FactoryBot.build(:enquiry, customer_email: "", customer_phone: "")

    expect(enquiry).not_to be_valid
    expect(enquiry.errors[:base]).to include("Add an email address or a phone number so we can reply.")
  end

  it "flags suspicious messages as spam" do
    enquiry = FactoryBot.create(
      :enquiry,
      customer_email: "growth@mailinator.com",
      message: "Get crypto backlinks today at https://spam.example and https://spam2.example."
    )

    expect(enquiry).to be_spam
    expect(enquiry.spam_reason).to eq("Automatic spam heuristic")
  end

  it "generates a lead reference automatically" do
    enquiry = FactoryBot.create(:enquiry)

    expect(enquiry.lead_reference).to match(/\AGTK-ENQ-[A-Z0-9]{8}\z/)
  end
end
