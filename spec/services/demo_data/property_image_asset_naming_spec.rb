require "rails_helper"
require "fileutils"

RSpec.describe DemoData::PropertyImageAssetNaming do
  it "accepts the current property image asset filenames" do
    filenames = Dir.glob(Rails.root.join("app/assets/images/properties/*"))
      .select { |path| File.file?(path) }
      .map { |path| File.join("properties", File.basename(path)) }

    expect(filenames).not_to be_empty
    expect(filenames).to all(satisfy { |filename| described_class.valid_property_asset_filename?(filename) })
  end

  it "finds supplementary images for a hero image in numeric order" do
    hero_filename = "properties/property_example_house_hero.webp"
    asset_root = Rails.root.join("app/assets/images/properties")
    created_paths = [
      asset_root.join("property_example_house_supp_2.webp"),
      asset_root.join("property_example_house_supp_1.webp")
    ]

    created_paths.each do |path|
      FileUtils.mkdir_p(path.dirname)
      File.binwrite(path, "supplementary-image")
    end

    expect(described_class.supplementary_filenames_for(hero_filename)).to eq([
      "properties/property_example_house_supp_1.webp",
      "properties/property_example_house_supp_2.webp"
    ])
  ensure
    created_paths&.each { |path| FileUtils.rm_f(path) }
  end
end
