# frozen_string_literal: true

require "json"

def integer_env(name, default: nil)
  value = ENV[name]
  value.present? ? Integer(value) : default
end

property_ids =
  ENV.fetch("PROPERTY_IDS", "")
     .split(",")
     .map(&:strip)
     .reject(&:blank?)
     .map(&:to_i)
selected_property_ids = property_ids.presence

sale_status = ENV["SALE_STATUS"].presence
town_city = ENV["TOWN_CITY"].presence
limit = integer_env("LIMIT", default: 5)
batch_size = integer_env("BATCH_SIZE", default: DemoData::PropertyImageGenerator::DEFAULT_BATCH_SIZE)

scope = DemoData::PropertyImageGenerator.filtered_scope(
  property_ids: selected_property_ids,
  sale_status: sale_status,
  town_city: town_city
)
generator = DemoData::PropertyImageGenerator.new(dry_run: true, batch_size: batch_size)
report = generator.generate_for_scope(scope, limit: limit)

report_path = Rails.root.join("tmp/property_image_prompt_preview.json")
File.write(report_path, JSON.pretty_generate(report))

report.fetch(:results).each do |result|
  puts "\n=== Property ##{result.fetch(:property_id)} | #{result.fetch(:address_line_1)}, #{result.fetch(:town_city)} ==="
  puts "Target file: #{result.fetch(:filename)}"
  build_year = result[:year_built].presence || "Unknown"
  refurbishment = result[:refurbished_year].presence || "Unknown"
  puts "Built: #{build_year} | Refurbished: #{refurbishment}"
  puts result.fetch(:prompt)
end

puts "\nPreviewed #{report[:previewed]} prompts."
puts "Processed #{report[:batches]} batch(es) of up to #{report[:batch_size]} properties."
puts "Report written to #{report_path}."
