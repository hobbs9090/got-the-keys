require "rails_helper"

RSpec.describe PropertyDocument do
  it "validates category and visibility" do
    document = FactoryBot.build(:property_document, category: "unsupported", visibility: "secret")

    expect(document).not_to be_valid
    expect(document.errors[:category]).to be_present
    expect(document.errors[:visibility]).to be_present
  end

  it "does not offer EPC as a supported document category" do
    expect(described_class::CATEGORIES).not_to include("epc")
  end

  it "knows whether it is public" do
    expect(FactoryBot.build(:property_document, visibility: "public")).to be_publicly_visible
    expect(FactoryBot.build(:property_document, visibility: "private")).not_to be_publicly_visible
  end
end
