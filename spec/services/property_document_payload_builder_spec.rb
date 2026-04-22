require "rails_helper"

RSpec.describe PropertyDocumentPayloadBuilder do
  # Decode all hex string literals from a Prawn-generated PDF content stream so
  # content assertions work regardless of raw byte encoding.
  def pdf_text(payload)
    payload.scan(/<([0-9a-fA-F]{4,})>/).map { |(hex)| [hex].pack("H*") }.join(" ")
  end

  let(:property) do
    FactoryBot.create(
      :property,
      address_line_1: "24 Cedar Road",
      town_city: "Sevenoaks",
      county: "Kent",
      postcode: "TN13 1AA",
      property_type: "House",
      listing_tagline: "Architect-designed family home",
      property_description: "A bright, design-led family home with a generous kitchen diner, landscaped garden, and flexible study space for hybrid working.",
      bedrooms: 4,
      bathrooms: 3,
      asking_price: 1_050_000,
      floor_area_sq_ft: 2150,
      year_built: 1934,
      refurbished_year: 2021
    )
  end
  let(:document) do
    FactoryBot.create(
      :property_document,
      property:,
      title: "Sales brochure",
      file_name: "cedar-road-brochure.pdf",
      category: "brochure",
      visibility: "public"
    )
  end

  it "builds a branded PDF property sheet with the listing hero image" do
    FactoryBot.create(
      :photo,
      property:,
      image_filename: "properties/property_18_cedar_road_hero.webp",
      primary: true,
      position: 1
    )

    payload = described_class.new(document:, property:).payload
    text = pdf_text(payload)

    expect(payload).to start_with("%PDF-1.")
    expect(text).to include("PROPERTY PLATFORM")
    expect(text).to include("gotthekeys")
    expect(text).to include("SALES BROCHURE")
    expect(text).to include("24 Cedar Road")
    expect(text).to include("Overview")
    expect(text).to include("Key facts")
    expect(text).to include("1,050,000")
    expect(text).not_to include("GBP 1,050,000")
    expect(text).to include("Guide price")
    expect(text).to include("Updated 2021  |  2150 sq ft")
    expect(text).not_to include("Built 1934")
    expect(text).to include("01732 650010  |  hello@gotthekeys.com")
    expect(text).not_to include(AppSettings.primary_branch_profile.fetch(:response_time))
    expect(text).not_to include(I18n.t("ui.branch_profile.team_label"))
    expect(payload).to include("/Subtype /Image")
  end

  it "renders a styled placeholder when the property has no hero image" do
    payload = described_class.new(document:, property:).payload
    text = pdf_text(payload)

    expect(payload).to start_with("%PDF-1.")
    expect(text).to include("Image coming soon")
    expect(text).to include("SALES BROCHURE")
    expect(payload).not_to include("/Subtype /Image")
  end

  it "builds branded compliance sheets with the same property-summary layout" do
    compliance_document = FactoryBot.create(
      :property_document,
      property:,
      title: "Compliance pack",
      file_name: "cedar-road-compliance.pdf",
      category: "compliance",
      visibility: "public"
    )

    payload = described_class.new(document: compliance_document, property:).payload
    text = pdf_text(payload)

    expect(payload).to start_with("%PDF-1.")
    expect(text).to include("COMPLIANCE PACK")
    expect(text).to include("PROPERTY PLATFORM")
    expect(text).to include("24 Cedar Road")
    expect(text).to include("1,050,000")
    expect(text).to include("Prepared #{Date.current.strftime('%d %B %Y')}")
    expect(text).not_to include(AppSettings.primary_branch_profile.fetch(:response_time))
  end

  it "shows FOR RENT badge and omits price label for rental properties" do
    rental_property = FactoryBot.create(:property, :for_rent, asking_price: 2200)
    rental_document = FactoryBot.create(:property_document, property: rental_property, file_name: "let.pdf")

    text = pdf_text(described_class.new(document: rental_document, property: rental_property).payload)

    expect(text).to include("FOR RENT")
    expect(text).not_to include("FOR SALE")
  end

  it "falls back to a plain text payload for non-pdf documents" do
    docx_document = FactoryBot.create(
      :property_document,
      property:,
      title: "Sales brochure",
      file_name: "cedar-road-brochure.docx",
      category: "brochure",
      visibility: "public"
    )

    payload = described_class.new(document: docx_document, property:).payload

    expect(payload).not_to start_with("%PDF-1.4")
    expect(payload).to include("GotTheKeys document download")
    expect(payload).to include("Title: Sales brochure")
    expect(payload).to include("Property: 24 Cedar Road")
  end
end
