class NormalizePropertyImageFilenames < ActiveRecord::Migration[8.1]
  class MigrationPhoto < ApplicationRecord
    self.table_name = "photos"
  end

  class MigrationProperty < ApplicationRecord
    self.table_name = "properties"
  end

  LEGACY_FILENAME_MAPPINGS = {
    "sevenoaks_family_home_hero.jpg" => "properties/property_sevenoaks_family_home_hero.jpg",
    "properties/sevenoaks_family_home_hero.jpg" => "properties/property_sevenoaks_family_home_hero.jpg",
    "tunbridge_garden_flat_hero.jpg" => "properties/property_tunbridge_garden_flat_hero.jpg",
    "properties/tunbridge_garden_flat_hero.jpg" => "properties/property_tunbridge_garden_flat_hero.jpg",
    "guildford_townhouse_hero.jpg" => "properties/property_guildford_townhouse_hero.jpg",
    "properties/guildford_townhouse_hero.jpg" => "properties/property_guildford_townhouse_hero.jpg",
    "croydon_rental_loft_hero.jpg" => "properties/property_croydon_rental_loft_hero.jpg",
    "properties/croydon_rental_loft_hero.jpg" => "properties/property_croydon_rental_loft_hero.jpg",
    "baseline_rental_001_hero.jpg" => "properties/property_baseline_rental_001_hero.jpg",
    "properties/baseline_rental_001_hero.jpg" => "properties/property_baseline_rental_001_hero.jpg",
    "baseline_sale_001_hero.jpg" => "properties/property_baseline_sale_001_hero.jpg",
    "properties/baseline_sale_001_hero.jpg" => "properties/property_baseline_sale_001_hero.jpg",
    "baseline_sale_002_hero.jpg" => "properties/property_baseline_sale_002_hero.jpg",
    "properties/baseline_sale_002_hero.jpg" => "properties/property_baseline_sale_002_hero.jpg",
    "baseline_sale_003_hero.jpg" => "properties/property_baseline_sale_003_hero.jpg",
    "properties/baseline_sale_003_hero.jpg" => "properties/property_baseline_sale_003_hero.jpg",
    "baseline_sale_004_hero.jpg" => "properties/property_baseline_sale_004_hero.jpg",
    "properties/baseline_sale_004_hero.jpg" => "properties/property_baseline_sale_004_hero.jpg",
    "baseline_sale_005_hero.jpg" => "properties/property_baseline_sale_005_hero.jpg",
    "properties/baseline_sale_005_hero.jpg" => "properties/property_baseline_sale_005_hero.jpg"
  }.freeze

  FINAL_TO_LEGACY_FILENAME_MAPPINGS = {
    "properties/property_sevenoaks_family_home_hero.jpg" => "sevenoaks_family_home_hero.jpg",
    "properties/property_tunbridge_garden_flat_hero.jpg" => "tunbridge_garden_flat_hero.jpg",
    "properties/property_guildford_townhouse_hero.jpg" => "guildford_townhouse_hero.jpg",
    "properties/property_croydon_rental_loft_hero.jpg" => "croydon_rental_loft_hero.jpg",
    "properties/property_baseline_rental_001_hero.jpg" => "baseline_rental_001_hero.jpg",
    "properties/property_baseline_sale_001_hero.jpg" => "baseline_sale_001_hero.jpg",
    "properties/property_baseline_sale_002_hero.jpg" => "baseline_sale_002_hero.jpg",
    "properties/property_baseline_sale_003_hero.jpg" => "baseline_sale_003_hero.jpg",
    "properties/property_baseline_sale_004_hero.jpg" => "baseline_sale_004_hero.jpg",
    "properties/property_baseline_sale_005_hero.jpg" => "baseline_sale_005_hero.jpg"
  }.freeze

  def up
    normalize_records(MigrationPhoto, :image_filename)
    normalize_records(MigrationProperty, :image_file_name)
  end

  def down
    restore_records(MigrationPhoto, :image_filename)
    restore_records(MigrationProperty, :image_file_name)
  end

  private

  def normalize_records(model, column)
    LEGACY_FILENAME_MAPPINGS.each do |from, to|
      model.where(column => from).update_all(column => to)
    end

    model.find_each do |record|
      value = record.public_send(column)
      next if value.blank?

      normalized = normalize_generated_filename(value)
      next if normalized == value

      record.update_columns(column => normalized)
    end
  end

  def restore_records(model, column)
    model.find_each do |record|
      value = record.public_send(column)
      next if value.blank?

      restored = restore_generated_filename(value)
      next if restored == value

      record.update_columns(column => restored)
    end

    FINAL_TO_LEGACY_FILENAME_MAPPINGS.each do |from, to|
      model.where(column => from).update_all(column => to)
    end
  end

  def normalize_generated_filename(value)
    value.sub(/\A(?:properties\/)?generated_property_(\d+)\.(gif|jpg|jpeg|png|svg)\z/i, "properties/property_\\1_hero.\\2")
  end

  def restore_generated_filename(value)
    value.sub(/\Aproperties\/property_(\d+)_hero\.(gif|jpg|jpeg|png|svg)\z/i, "generated_property_\\1.\\2")
  end
end
