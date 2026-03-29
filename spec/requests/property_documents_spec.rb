require "rails_helper"

RSpec.describe "Property documents", type: :request do
  let(:property) { FactoryBot.create(:property, address_line_1: "31 Granville Road") }
  let(:owner) { property.user }

  it "lets the owner add a document" do
    sign_in owner

    expect do
      post property_property_documents_path(property), params: {
        property_document: {
          title: "Sales brochure",
          file_name: "granville-road-brochure.pdf",
          category: "brochure",
          visibility: "public",
          position: 1
        }
      }
    end.to change(PropertyDocument, :count).by(1)
      .and change(AuditLog, :count).by(1)

    expect(response).to redirect_to(property_property_documents_path(property))
  end

  it "allows public visitors to download public documents" do
    document = FactoryBot.create(:property_document, property:, title: "Sales brochure", file_name: "granville-road-brochure.pdf")
    FactoryBot.create(:photo, property:, image_filename: "sevenoaks_family_home_hero.jpg", primary: true, position: 1)

    get download_property_property_document_path(property, document)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.headers["Content-Disposition"]).to include("granville-road-brochure.pdf")
    expect(response.body).to start_with("%PDF-1.4")
    expect(response.body).to include("PROPERTY PLATFORM")
    expect(response.body).to include("SALES BROCHURE")
    expect(response.body).to include("31 Granville Road")
    expect(response.body).to include("/Subtype /Image")
  end

  it "blocks public visitors from downloading private documents" do
    document = FactoryBot.create(:property_document, :private_document, property:, title: "Compliance pack")

    get download_property_property_document_path(property, document)

    expect(response).to redirect_to(property_path(property))
  end

  it "renders public download links as regular browser downloads on the property page" do
    document = FactoryBot.create(:property_document, property:, title: "EPC certificate", file_name: "granville-road-epc.pdf")

    get property_path(property)

    page = Nokogiri::HTML(response.body)
    download_link = page.at_css(%([data-testid="property-document-download-#{document.id}"]))

    expect(download_link).to be_present
    expect(download_link["data-turbo"]).to eq("false")
    expect(download_link["download"]).to eq("granville-road-epc.pdf")
  end

  it "renders owner document-list download links as regular browser downloads" do
    sign_in owner
    document = FactoryBot.create(:property_document, property:, title: "Sales brochure", file_name: "granville-road-brochure.pdf")

    get property_property_documents_path(property)

    page = Nokogiri::HTML(response.body)
    download_link = page.at_css(%(a[href="#{download_property_property_document_path(property, document)}"]))

    expect(download_link).to be_present
    expect(download_link["data-turbo"]).to eq("false")
    expect(download_link["download"]).to eq("granville-road-brochure.pdf")
  end
end
