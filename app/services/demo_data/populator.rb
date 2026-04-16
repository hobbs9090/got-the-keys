module DemoData
  class Populator
    DEFAULT_USER_COUNT = 20
    DEFAULT_PROPERTY_COUNT = 40
    DEFAULT_BATCH_SIZE = 8
    ENGLISH_FIRST_NAMES = %w[
      Charlotte
      Oliver
      Amelia
      George
      Sophie
      Thomas
      Emily
      James
      Lucy
      Henry
      Grace
      Daniel
      Alice
      William
      Hannah
      Edward
      Ruby
      Samuel
      Katie
      Matthew
    ].freeze
    ENGLISH_LAST_NAMES = %w[
      Hughes
      Bennett
      Carter
      Dawson
      Mercer
      Collins
      Turner
      Harrison
      Whitmore
      Fletcher
      Parker
      Lawson
      Reed
      Cooper
      Barrett
      Hayes
      Foster
      Chambers
      Webb
      Morgan
    ].freeze
    SAFE_EMAIL_DOMAINS = %w[gmail.example outlook.example icloud.example btinternet.example].freeze

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
      @generated_user_count = User.count
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
      sequence, first_name, last_name = next_available_user_identity

      User.create!(
        first_name: first_name,
        last_name: last_name,
        language: 'en',
        mobile_number: generated_mobile_number_for(sequence),
        email: generated_email_for(first_name:, last_name:, sequence:),
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

    def next_user_sequence
      sequence = @generated_user_count
      @generated_user_count += 1
      sequence
    end

    def next_available_user_identity
      loop do
        sequence = next_user_sequence
        first_name, last_name = generated_name_for(sequence)
        email = generated_email_for(first_name:, last_name:, sequence:)

        return [sequence, first_name, last_name] unless User.exists?(email: email)
      end
    end

    def generated_name_for(sequence)
      first_name = ENGLISH_FIRST_NAMES.fetch(sequence % ENGLISH_FIRST_NAMES.length)
      last_name = ENGLISH_LAST_NAMES.fetch((sequence / ENGLISH_FIRST_NAMES.length + sequence) % ENGLISH_LAST_NAMES.length)

      [first_name, last_name]
    end

    def generated_email_for(first_name:, last_name:, sequence:)
      base = "#{first_name}.#{last_name}".parameterize(separator: '.')
      suffix = sequence >= ENGLISH_FIRST_NAMES.length ? sequence / ENGLISH_FIRST_NAMES.length + 1 : nil
      domain = SAFE_EMAIL_DOMAINS.fetch(sequence % SAFE_EMAIL_DOMAINS.length)

      "#{base}#{suffix}@#{domain}"
    end

    def generated_mobile_number_for(sequence)
      "07700 #{format('%06d', 900_100 + sequence)}"
    end
  end
end
