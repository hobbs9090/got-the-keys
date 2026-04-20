# frozen_string_literal: true

class NormalizePropertyTypesToHouseOrFlat < ActiveRecord::Migration[8.1]
  class MigrationProperty < ApplicationRecord
    self.table_name = "properties"
  end

  def up
    flat_pattern = /flat|apartment|maisonette|loft|penthouse|studio|duplex/i

    MigrationProperty.find_each do |record|
      next if %w[House Flat].include?(record.property_type)

      new_type = record.property_type.to_s.match?(flat_pattern) ? "Flat" : "House"
      record.update_columns(property_type: new_type)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
