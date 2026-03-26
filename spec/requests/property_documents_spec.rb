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

    get download_property_property_document_path(property, document)

    expect(response).to have_http_status(:ok)
    expect(response.headers["Content-Disposition"]).to include("granville-road-brochure.pdf")
    expect(response.body).to include("GotTheKeys document download")
  end

  it "blocks public visitors from downloading private documents" do
    document = FactoryBot.create(:property_document, :private_document, property:, title: "Compliance pack")

    get download_property_property_document_path(property, document)

    expect(response).to redirect_to(property_path(property))
  end
end
