# frozen_string_literal: true

require "base64"
require "fileutils"

module DemoData
  class PropertyImageGenerator
    DEFAULT_MODEL = "gpt-image-1.5".freeze
    DEFAULT_QUALITY = "high".freeze
    DEFAULT_SIZE = "1536x1024".freeze
    DEFAULT_OUTPUT_FORMAT = "jpeg".freeze
    DEFAULT_OUTPUT_COMPRESSION = 90

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
      output_dir: Rails.root.join("app/assets/images"),
      logger: Rails.logger,
      prompt_builder: PropertyImagePromptBuilder.new,
      dry_run: false,
      force: false
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
    end

    def generate_for_scope(scope, limit: nil)
      selected_scope = limit.present? ? scope.limit(limit) : scope
      results = selected_scope.map { |property| generate_for_property(property) }

      {
        model: model,
        quality: quality,
        size: size,
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

      FileUtils.mkdir_p(output_dir)

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
      File.binwrite(output_path, Base64.decode64(image.b64_json))
      property.update!(image_file_name: filename)

      base_result(property, filename, prompt).merge(
        status: :generated,
        path: output_path.to_s,
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

    attr_reader :api_key, :model, :quality, :size, :output_format, :output_compression, :output_dir, :logger, :prompt_builder

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
      "generated_property_#{property.id}.#{filename_extension}"
    end

    def skip_generation?(property, filename)
      return false if force?
      return false if property.image_file_name.blank?

      existing_filename = property.image_file_name.to_s
      return true if existing_filename != filename

      output_dir.join(existing_filename).exist?
    end

    def base_result(property, filename, prompt)
      {
        property_id: property.id,
        address_line_1: property.address_line_1,
        town_city: property.town_city,
        sale_status: property.sale_status,
        filename: filename,
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
