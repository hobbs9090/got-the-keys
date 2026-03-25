# frozen_string_literal: true

require "json"

def truthy_env?(value)
  %w[1 true yes on].include?(value.to_s.strip.downcase)
end

def integer_env(name)
  value = ENV[name]
  value.present? ? Integer(value) : nil
end

def string_env(name)
  ENV[name].presence
end

property_ids =
  ENV.fetch("PROPERTY_IDS", "")
     .split(",")
     .map(&:strip)
     .reject(&:blank?)
     .map(&:to_i)
selected_property_ids = property_ids.presence

sale_status = string_env("SALE_STATUS")
town_city = string_env("TOWN_CITY")
limit = integer_env("LIMIT")
force = truthy_env?(ENV["FORCE"])
model = string_env("MODEL")
quality = string_env("QUALITY")
size = string_env("SIZE")
output_format = string_env("OUTPUT_FORMAT")
output_compression = integer_env("OUTPUT_COMPRESSION")

abort "OPENAI_API_KEY is required. Use `bin/rails runner script/preview_property_image_prompts.rb` to review prompts without generating images." if ENV["OPENAI_API_KEY"].blank?

scope = DemoData::PropertyImageGenerator.filtered_scope(
  property_ids: selected_property_ids,
  sale_status: sale_status,
  town_city: town_city
)
generator = DemoData::PropertyImageGenerator.new(
  force: force,
  model: model || DemoData::PropertyImageGenerator::DEFAULT_MODEL,
  quality: quality || DemoData::PropertyImageGenerator::DEFAULT_QUALITY,
  size: size || DemoData::PropertyImageGenerator::DEFAULT_SIZE,
  output_format: output_format || DemoData::PropertyImageGenerator::DEFAULT_OUTPUT_FORMAT,
  output_compression: output_compression || DemoData::PropertyImageGenerator::DEFAULT_OUTPUT_COMPRESSION
)
report = generator.generate_for_scope(scope, limit: limit)

report_path = Rails.root.join("tmp/property_image_generation_report.json")
File.write(report_path, JSON.pretty_generate(report))

puts "Generated #{report[:generated]} property images, skipped #{report[:skipped]}, failed #{report[:failed]}."
puts "Report written to #{report_path}."
