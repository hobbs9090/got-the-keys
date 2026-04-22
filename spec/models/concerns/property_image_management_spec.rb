require "rails_helper"

RSpec.describe PropertyImageManagement do
  let(:user) { FactoryBot.create(:user) }
  let(:property) { FactoryBot.create(:property, user:) }

  it "is included in Property" do
    expect(Property.ancestors).to include(described_class)
  end

  it "rejects an SVG upload as the hero image upload" do
    svg_file = double("upload", original_filename: "icon.svg", content_type: "image/svg+xml", blank?: false)
    property.image_upload = svg_file
    expect(property.valid?).to be false
    expect(property.errors[:image_upload]).to be_present
  end

  it "accepts a JPEG upload as the hero image upload" do
    jpeg_file = double("upload", original_filename: "photo.jpg", content_type: "image/jpeg", blank?: false)
    property.image_upload = jpeg_file
    expect(property.errors[:image_upload]).to be_empty
  end
end
