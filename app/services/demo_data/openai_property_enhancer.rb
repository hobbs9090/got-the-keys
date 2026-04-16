require 'json'

module DemoData
  class OpenaiPropertyEnhancer
    DEFAULT_MODEL = DemoData::OpenaiEnrichmentModels::DEFAULT
    AVAILABLE_MODELS = DemoData::OpenaiEnrichmentModels::AVAILABLE

    JSON_SCHEMA = {
      type: 'object',
      properties: {
        properties: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              asking_price: { type: 'integer', minimum: 750, maximum: 2_500_000 },
              property_description: { type: 'string', minLength: 60, maxLength: 420 }
            },
            required: %w[asking_price property_description],
            additionalProperties: false
          }
        }
      },
      required: %w[properties],
      additionalProperties: false
    }.freeze

    def initialize(client: nil, api_key: ENV['OPENAI_API_KEY'], model: DEFAULT_MODEL, logger: Rails.logger)
      @client = client || OpenAI::Client.new(api_key: api_key, max_retries: 2)
      @model = model
      @logger = logger
    end

    def enhance_batch(blueprints)
      return blueprints if blueprints.empty?

      payload = JSON.parse(response_for(blueprints).output_text, symbolize_names: true)
      enriched_properties = payload.fetch(:properties)

      blueprints.each_with_index.map do |blueprint, index|
        merge_blueprint(blueprint, enriched_properties.fetch(index))
      end
    rescue StandardError => error
      logger.warn("OpenAI seed enrichment failed: #{error.class}: #{error.message}")
      blueprints
    end

    private

    attr_reader :client, :model, :logger

    def response_for(blueprints)
      client.responses.create(
        model: model,
        input: [
          { role: :system, content: system_prompt },
          { role: :user, content: user_prompt(blueprints) }
        ],
        text: {
          format: {
            type: :json_schema,
            name: 'property_seed_batch',
            strict: true,
            schema: JSON_SCHEMA
          }
        }
      )
    end

    def system_prompt
      <<~PROMPT
        You enrich demo residential property seed data for a UK property marketplace.
        Return valid JSON only.
        Keep the number of returned properties exactly equal to the input array length and preserve order.
        For each property:
        - Keep the sale or rent context.
        - Treat asking_price as GBP.
        - For "For Sale", keep the price in a realistic sale range.
        - For "For Rent", keep the price as a realistic monthly rent.
        - Stay close to the supplied base price unless local context strongly suggests a modest adjustment.
        - Write natural British-English listing copy in 2 to 4 sentences.
        - Mention layout, condition, and local convenience without sounding repetitive or exaggerated.
        - Keep the tone credible for an English property portal rather than glossy marketing copy.
        - Do not invent unsafe claims, schools ratings, or legal guarantees.
      PROMPT
    end

    def user_prompt(blueprints)
      seed_payload = blueprints.map do |blueprint|
        {
          address_line_1: blueprint.fetch(:address_line_1),
          town_city: blueprint.fetch(:town_city),
          county: blueprint.fetch(:county),
          sale_status: blueprint.fetch(:sale_status),
          bedrooms: blueprint.fetch(:bedrooms),
          asking_price: blueprint.fetch(:asking_price),
          base_description: blueprint.fetch(:property_description),
          context: blueprint.fetch(:prompt_context)
        }
      end

      <<~PROMPT
        Improve the following property records for demo seed data.
        Return only the enriched JSON object that matches the schema.

        #{JSON.pretty_generate(properties: seed_payload)}
      PROMPT
    end

    def merge_blueprint(blueprint, enriched)
      sale_status = blueprint.fetch(:sale_status)
      base_price = blueprint.fetch(:asking_price)
      enriched_price = enriched.fetch(:asking_price)

      blueprint.merge(
        asking_price: sanitized_price(enriched_price, sale_status: sale_status, fallback: base_price),
        property_description: enriched.fetch(:property_description).to_s.strip
      )
    end

    def sanitized_price(value, sale_status:, fallback:)
      numeric = Integer(value)
      min, max =
        if sale_status == 'For Sale'
          [175_000, 2_500_000]
        else
          [750, 6_500]
        end

      [[numeric, min].max, max].min
    rescue ArgumentError, TypeError
      fallback
    end
  end
end
