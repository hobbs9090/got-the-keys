# frozen_string_literal: true

module DemoData
  class PropertyImageAssetNaming
    PROPERTY_ASSET_DIR = Rails.root.join("app/assets/images/properties")
    HERO_FILENAME_PATTERN = /\Aproperties\/(?<slug>property_.+)_hero\.(?<extension>jpg|jpeg|png|webp|gif|svg)\z/i.freeze
    SUPPLEMENTARY_BASENAME_PATTERN = /\A(?<slug>property_.+)_supp_(?<number>\d+)\.(?<extension>jpg|jpeg|png|webp|gif|svg)\z/i.freeze

    def self.valid_property_asset_filename?(filename)
      relative_path = filename.to_s
      return true if relative_path.match?(HERO_FILENAME_PATTERN)

      basename = File.basename(relative_path)
      relative_path.start_with?("properties/") && basename.match?(SUPPLEMENTARY_BASENAME_PATTERN)
    end

    def self.supplementary_assets_for(hero_filename)
      match = hero_filename.to_s.match(HERO_FILENAME_PATTERN)
      return [] unless match

      slug = match[:slug]

      PROPERTY_ASSET_DIR
        .glob("#{slug}_supp_*.*")
        .select(&:file?)
        .filter_map do |path|
          basename = path.basename.to_s
          supplementary_match = basename.match(SUPPLEMENTARY_BASENAME_PATTERN)
          next unless supplementary_match
          next unless supplementary_match[:slug] == slug

          { filename: File.join("properties", basename), number: supplementary_match[:number].to_i }
        end
        .sort_by { |entry| [entry[:number], entry[:filename]] }
    end

    def self.supplementary_filenames_for(hero_filename)
      supplementary_assets_for(hero_filename).map { |entry| entry[:filename] }
    end
  end
end
