require "rails_helper"

RSpec.describe "Photos", type: :request do
  let(:property) { FactoryBot.create(:property, address_line_1: "10 Willow Lane") }
  let(:owner) { property.user }

  it "prefills the first photo form as the primary image" do
    sign_in owner

    get property_photos_path(property)

    page = Nokogiri::HTML(response.body)
    primary_checkbox = page.at_css('input[type="checkbox"][name="photo[primary]"]')

    expect(response).to have_http_status(:ok)
    expect(primary_checkbox).to be_present
    expect(primary_checkbox["checked"]).to eq("checked")
  end

  it "creates a photo from an uploaded image file" do
    sign_in owner

    expect do
      post property_photos_path(property), params: {
        photo: {
          image_upload: Rack::Test::UploadedFile.new(
            Rails.root.join("spec/fixtures/files/property-upload.jpeg"),
            "image/jpeg"
          ),
          caption: "Front elevation",
          position: 1,
          primary: true
        }
      }
    end.to change(Photo, :count).by(1)

    photo = property.photos.order(:id).last

    expect(response).to redirect_to(property_photos_path(property))
    expect(photo.image_filename).to match(%r{\A/uploads/property_photos/#{property.id}/#{photo.id}/[0-9a-f]{32}\.jpeg\z})
    expect(Rails.root.join("tmp", "uploads", photo.image_filename.delete_prefix("/uploads/"))).to exist
  end
end
