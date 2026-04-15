class ConvertSeedPropertyHeroImagesToWebp < ActiveRecord::Migration[8.1]
  class MigrationPhoto < ApplicationRecord
    self.table_name = "photos"
  end

  class MigrationProperty < ApplicationRecord
    self.table_name = "properties"
  end

  JPG_HERO_PATTERN = /\Aproperties\/property_.*_hero(?:@2x)?\.(?:jpe?g)\z/i.freeze
  WEBP_HERO_PATTERN = /\Aproperties\/property_.*_hero(?:@2x)?\.webp\z/i.freeze

  def up
    rewrite_column(MigrationPhoto, :image_filename, from: JPG_HERO_PATTERN, to_extension: ".webp")
    rewrite_column(MigrationProperty, :image_file_name, from: JPG_HERO_PATTERN, to_extension: ".webp")
  end

  def down
    rewrite_column(MigrationPhoto, :image_filename, from: WEBP_HERO_PATTERN, to_extension: ".jpg")
    rewrite_column(MigrationProperty, :image_file_name, from: WEBP_HERO_PATTERN, to_extension: ".jpg")
  end

  private

  def rewrite_column(model, column, from:, to_extension:)
    say_with_time("Updating #{model.table_name}.#{column} references to #{to_extension}") do
      updated = 0

      model.find_each do |record|
        source = record.public_send(column).to_s
        next unless source.match?(from)

        record.update_columns(column => source.sub(/\.[^.]+\z/, to_extension))
        updated += 1
      end

      updated
    end
  end
end
