module DemoData
  class Populator
    DEFAULT_USER_COUNT = 20
    DEFAULT_PROPERTY_COUNT = 40
    DEFAULT_BATCH_SIZE = 8

    def self.ai_mode_from_env(value)
      normalized = value.to_s.strip.downcase

      case normalized
      when '', 'auto'
        :auto
      when '1', 'true', 'on', 'enabled'
        :on
      when '0', 'false', 'off', 'disabled'
        :off
      else
        raise ArgumentError, "Unsupported SEED_AI_MODE value: #{value.inspect}"
      end
    end

    def initialize(
      user_count: DEFAULT_USER_COUNT,
      property_count: DEFAULT_PROPERTY_COUNT,
      password: 'secret',
      users: nil,
      ai_mode: :auto,
      batch_size: DEFAULT_BATCH_SIZE,
      model: OpenaiPropertyEnhancer::DEFAULT_MODEL,
      logger: Rails.logger,
      blueprint_generator: PropertyBlueprintGenerator.new,
      enhancer: nil
    )
      @user_count = user_count
      @property_count = property_count
      @password = password
      @users = users
      @ai_mode = ai_mode
      @batch_size = batch_size
      @model = model
      @logger = logger
      @blueprint_generator = blueprint_generator
      @enhancer = enhancer
    end

    def populate!
      owners = seed_users
      created_properties = 0

      property_blueprints.each_slice(batch_size) do |batch|
        enriched_batch(batch).each_with_index do |attributes, index|
          owner = owners[(created_properties + index) % owners.length]
          Property.create!(property_attributes(attributes).merge(user: owner))
        end

        created_properties += batch.length
      end

      {
        users_used: owners.length,
        properties_created: created_properties,
        ai_mode: effective_ai_mode,
        model: ai_enabled? ? model : nil
      }
    end

    private

    attr_reader :user_count, :property_count, :password, :users, :ai_mode, :batch_size, :model, :logger, :blueprint_generator

    def property_blueprints
      blueprint_generator.build_batch(count: property_count)
    end

    def seed_users
      return Array(users) if users.present?

      Array.new(user_count) { create_user }
    end

    def create_user
      User.create!(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        language: AppSettings.available_languages.sample,
        mobile_number: ['07595 123456', '07955 654321', '07955 123123', '+44 7887 112233'].sample,
        email: Faker::Internet.unique.email,
        password: password,
        password_confirmation: password,
        terms_of_service: true
      )
    end

    def enriched_batch(batch)
      return batch unless ai_enabled?

      enhancer.enhance_batch(batch)
    end

    def enhancer
      @enhancer ||= OpenaiPropertyEnhancer.new(model: model, logger: logger)
    end

    def ai_enabled?
      @ai_enabled ||=
        case ai_mode
        when :off
          false
        when :auto
          ENV['OPENAI_API_KEY'].present?
        when :on
          raise ArgumentError, 'SEED_AI_MODE=on requires OPENAI_API_KEY to be set' if ENV['OPENAI_API_KEY'].blank?

          true
        else
          false
        end
    end

    def effective_ai_mode
      ai_enabled? ? :on : :off
    end

    def property_attributes(attributes)
      attributes.except(:prompt_context)
    end
  end
end
