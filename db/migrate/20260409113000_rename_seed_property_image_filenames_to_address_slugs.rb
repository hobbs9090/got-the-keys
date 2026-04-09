class RenameSeedPropertyImageFilenamesToAddressSlugs < ActiveRecord::Migration[8.1]
  class MigrationPhoto < ApplicationRecord
    self.table_name = "photos"
  end

  class MigrationProperty < ApplicationRecord
    self.table_name = "properties"
  end

  ASSET_FILENAME_MAPPINGS = {
    "properties/property_sevenoaks_family_home_hero.jpg" => "properties/property_18_cedar_road_hero.jpg",
    "properties/property_tunbridge_garden_flat_hero.jpg" => "properties/property_flat_3_44_mount_ephraim_hero.jpg",
    "properties/property_guildford_townhouse_hero.jpg" => "properties/property_72_quarry_street_hero.jpg",
    "properties/property_croydon_rental_loft_hero.jpg" => "properties/property_apartment_11_9_park_lane_hero.jpg",
    "properties/property_baseline_rental_001_hero.jpg" => "properties/property_maisonette_7_6_queens_terrace_hero.jpg",
    "properties/property_baseline_sale_001_hero.jpg" => "properties/property_6_south_mews_hero.jpg",
    "properties/property_baseline_sale_002_hero.jpg" => "properties/property_8_richmond_grove_hero.jpg",
    "properties/property_baseline_sale_003_hero.jpg" => "properties/property_10_meadow_court_hero.jpg",
    "properties/property_baseline_sale_004_hero.jpg" => "properties/property_flat_17_12_rectory_place_hero.jpg",
    "properties/property_baseline_sale_005_hero.jpg" => "properties/property_flat_1_14_grosvenor_lane_hero.jpg",
    "properties/property_3654_hero.jpg" => "properties/property_16_kings_crescent_hero.jpg",
    "properties/property_3655_hero.jpg" => "properties/property_18_mount_road_hero.jpg",
    "properties/property_surrey_detached_garden_hero.jpg" => "properties/property_52_mount_lane_hero.jpg"
  }.freeze

  REVERSE_ASSET_FILENAME_MAPPINGS = ASSET_FILENAME_MAPPINGS.invert.freeze

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
    model.find_each do |record|
      value = record.public_send(column)
      next if value.blank?

      normalized = ASSET_FILENAME_MAPPINGS.fetch(value, normalize_generated_filename(record, value))
      next if normalized == value

      record.update_columns(column => normalized)
    end
  end

  def restore_records(model, column)
    model.find_each do |record|
      value = record.public_send(column)
      next if value.blank?

      restored = REVERSE_ASSET_FILENAME_MAPPINGS.fetch(value, restore_generated_filename(record, value))
      next if restored == value

      record.update_columns(column => restored)
    end
  end

  def normalize_generated_filename(record, value)
    return value unless value.match?(%r{\Aproperties/(?:generated_property_\d+|property_\d+_hero)\.(gif|jpg|jpeg|png|svg)\z}i)

    "properties/property_#{address_slug_for(record)}_hero.#{$1.downcase == 'jpeg' ? 'jpg' : $1.downcase}"
  end

  def restore_generated_filename(record, value)
    return value unless value.match?(%r{\Aproperties/property_.+_hero\.(gif|jpg|jpeg|png|svg)\z}i)

    extension = Regexp.last_match(1)
    "properties/property_#{generated_identifier_for(record)}_hero.#{extension}"
  end

  def address_slug_for(record)
    source_record = source_property_for(record)
    source_record.address_line_1.to_s.parameterize(separator: "_").presence || generated_identifier_for(record)
  end

  def generated_identifier_for(record)
    source_record = source_property_for(record)
    source_record.id.to_s
  end

  def source_property_for(record)
    return record if record.respond_to?(:address_line_1)

    MigrationProperty.find_by(id: record.property_id) || record
  end
end
