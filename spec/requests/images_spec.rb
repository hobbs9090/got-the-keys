require "rails_helper"

RSpec.describe "Images", type: :request do
  let(:property) { create(:property) }

  it "serves uploaded property photos inline" do
    photo = create(:photo, property:, image_filename: "/uploads/property_photos/#{property.id}/123/front.jpeg")
    image_path = Rails.root.join("tmp", "uploads", "property_photos", property.id.to_s, "123", "front.jpeg")
    FileUtils.mkdir_p(image_path.dirname)
    File.binwrite(image_path, "jpeg-bytes")

    get photo_image_path(photo)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("image/jpeg")
    expect(response.headers["Cache-Control"]).to include("public")
    expect(response.body).to eq("jpeg-bytes")
  ensure
    FileUtils.rm_rf(Rails.root.join("tmp", "uploads", "property_photos", property.id.to_s))
  end

  it "does not serve bundled asset photos by database id" do
    photo = create(:photo, property:, image_filename: "properties/property_18_cedar_road_hero.webp")

    get photo_image_path(photo)

    expect(response).to have_http_status(:not_found)
  end
end
