# frozen_string_literal: true

require "base64"
require "fileutils"

module DemoData
  class PropertyImageGenerator
    DEFAULT_BATCH_SIZE = 5
    DEFAULT_MODEL = "gpt-image-1.5".freeze
    DEFAULT_QUALITY = "high".freeze
    DEFAULT_SIZE = "1536x1024".freeze
    DEFAULT_OUTPUT_FORMAT = "jpeg".freeze
    DEFAULT_OUTPUT_COMPRESSION = 90
    PROPERTY_ASSET_SUBDIR = "properties".freeze
    DEFAULT_OUTPUT_DIR = Rails.root.join("app/assets/images").freeze

    def self.filtered_scope(property_ids: nil, sale_status: nil, town_city: nil)
      scope = Property.all
      scope = scope.where(id: property_ids) if property_ids.present?
      scope = scope.where(sale_status: sale_status) if sale_status.present?
      scope = scope.where(town_city: town_city) if town_city.present?
      scope.order(:id)
    end

    def initialize(
      client: nil,
      api_key: ENV["OPENAI_API_KEY"],
      model: DEFAULT_MODEL,
      quality: DEFAULT_QUALITY,
      size: DEFAULT_SIZE,
      output_format: DEFAULT_OUTPUT_FORMAT,
      output_compression: DEFAULT_OUTPUT_COMPRESSION,
      output_dir: DEFAULT_OUTPUT_DIR,
      logger: Rails.logger,
      prompt_builder: PropertyImagePromptBuilder.new,
      dry_run: false,
      force: false,
      batch_size: DEFAULT_BATCH_SIZE
    )
      @client = client
      @api_key = api_key
      @model = model
      @quality = quality
      @size = size
      @output_format = output_format
      @output_compression = output_compression
      @output_dir = Pathname(output_dir)
      @logger = logger
      @prompt_builder = prompt_builder
      @dry_run = dry_run
      @force = force
      @batch_size = batch_size
    end

    def generate_for_scope(scope, limit: nil)
      selected_properties = limit.present? ? scope.limit(limit).to_a : scope.to_a
      batches = selected_properties.each_slice(batch_size).to_a
      results = batches.flat_map.with_index(1) do |properties, batch_number|
        properties.map { |property| generate_for_property(property).merge(batch_number:) }
      end

      {
        model: model,
        quality: quality,
        size: size,
        batch_size: batch_size,
        batches: batches.size,
        output_dir: output_dir.to_s,
        dry_run: dry_run?,
        force: force?,
        processed: results.size,
        generated: results.count { |result| result[:status] == :generated },
        previewed: results.count { |result| result[:status] == :preview },
        skipped: results.count { |result| result[:status] == :skipped },
        failed: results.count { |result| result[:status] == :failed },
        results: results
      }
    end

    def generate_for_property(property)
      prompt = prompt_builder.prompt_for(property)
      filename = generated_filename_for(property)

      if skip_generation?(property, filename)
        return base_result(property, filename, prompt).merge(status: :skipped, reason: "existing_image_preserved")
      end

      return base_result(property, filename, prompt).merge(status: :preview) if dry_run?

      raise ArgumentError, "OPENAI_API_KEY is required to generate property images" if api_key.blank? && @client.blank?

      response = client.images.generate(
        prompt: prompt,
        model: model,
        quality: quality,
        size: size,
        output_format: output_format,
        output_compression: output_compression
      )

      image = response.data&.first
      raise "Image generation returned no image data for property #{property.id}" if image.blank?
      raise "Image generation returned no base64 payload for property #{property.id}" if image.b64_json.blank?

      output_path = output_dir.join(filename)
      FileUtils.mkdir_p(output_path.dirname)
      File.binwrite(output_path, Base64.decode64(image.b64_json))
      photo = attach_generated_photo(property, filename)

      base_result(property, filename, prompt).merge(
        status: :generated,
        path: output_path.to_s,
        photo_id: photo.id,
        revised_prompt: image.revised_prompt
      )
    rescue StandardError => error
      logger.error("Property image generation failed for property #{property.id}: #{error.class}: #{error.message}")

      base_result(property, filename, prompt).merge(
        status: :failed,
        error: "#{error.class}: #{error.message}"
      )
    end

    private

    attr_reader :api_key, :model, :quality, :size, :output_format, :output_compression, :output_dir, :logger, :prompt_builder, :batch_size

    def client
      @client ||= OpenAI::Client.new(api_key: api_key, max_retries: 2)
    end

    def dry_run?
      @dry_run
    end

    def force?
      @force
    end

    def generated_filename_for(property)
      File.join(PROPERTY_ASSET_SUBDIR, "property_#{property.id}_hero.#{filename_extension}")
    end

    def attach_generated_photo(property, filename)
      existing_photo = property.photos.find_by(image_filename: filename) || property.primary_photo
      next_position = property.photos.maximum(:position).to_i + 1

      if existing_photo.present?
        existing_photo.update!(
          image_filename: filename,
          caption: generated_caption_for(property),
          primary: true
        )
        existing_photo
      else
        property.photos.create!(
          image_filename: filename,
          caption: generated_caption_for(property),
          position: next_position,
          primary: true
        )
      end
    end

    def generated_caption_for(property)
      property.headline.presence || "#{property.property_type} in #{property.town_city}"
    end

    def skip_generation?(property, filename)
      return false if force?
      return true if property.hero_image_name.present?

      existing_photo = property.photos.find_by(image_filename: filename)
      existing_photo.present? && output_dir.join(existing_photo.image_filename.to_s).exist?
    end

    def base_result(property, filename, prompt)
      {
        property_id: property.id,
        address_line_1: property.address_line_1,
        town_city: property.town_city,
        year_built: property.year_built,
        refurbished_year: property.refurbished_year,
        sale_status: property.sale_status,
        filename: filename,
        asset_pipeline_managed: output_dir == DEFAULT_OUTPUT_DIR,
        output_format: output_format,
        prompt: prompt
      }
    end

    def filename_extension
      return "jpg" if output_format == "jpeg"

      output_format
    end
  end
end
