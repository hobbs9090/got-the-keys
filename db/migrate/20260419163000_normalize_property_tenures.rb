# frozen_string_literal: true

class NormalizePropertyTenures < ActiveRecord::Migration[8.1]
  ALLOWED = %w[Freehold Leasehold Commonhold Shared Ownership].freeze

  class MigrationProperty < ApplicationRecord
    self.table_name = "properties"
  end

  def up
    MigrationProperty.find_each do |record|
      normalized = normalize_tenure(record.tenure)
      next if normalized == record.tenure

      record.update_columns(tenure: normalized)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def normalize_tenure(value)
    return nil if value.blank?

    s = value.to_s.strip
    return s if ALLOWED.include?(s)

    key = s.downcase
    case key
    when "freehold" then "Freehold"
    when "leasehold" then "Leasehold"
    when "commonhold" then "Commonhold"
    when "shared ownership", "shared-ownership", "shared_ownership" then "Shared Ownership"
    else
      if key.include?("shared") && key.include?("ownership")
        "Shared Ownership"
      elsif key.include?("lease")
        "Leasehold"
      elsif key.include?("free")
        "Freehold"
      elsif key.include?("commonhold")
        "Commonhold"
      end
    end
  end
end
