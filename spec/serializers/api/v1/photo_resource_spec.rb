require "rails_helper"

RSpec.describe Api::V1::PhotoResource do
  describe ".render" do
    let(:host) { "https://example.test" }

    it "routes uploaded photo URLs through the image endpoint" do
      photo = build_stubbed(:photo, image_filename: "/uploads/property_photos/12/34/front.jpeg")

      payload = described_class.render(photo, host: host)

      expect(payload[:url]).to eq("https://example.test/img/#{photo.id}")
    end

    it "resolves bundled image filenames through the asset pipeline" do
      filename = "properties/property_18_cedar_road_hero.webp"
      photo = build_stubbed(:photo, image_filename: filename)

      payload = described_class.render(photo, host: host)

      expect(payload[:url]).to eq("#{host}#{ActionController::Base.helpers.asset_path(filename)}")
    end
  end
end
