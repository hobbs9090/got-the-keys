require "zlib"

module DemoData
  class ScenarioValidator
    class ValidationError < StandardError; end

    SCENARIO_FAMILIES = %w[happy_path edge_cases high_volume multilingual accessibility flaky_operator_workflow].freeze
    COMPLEXITY_LEVELS = %w[foundational intermediate advanced].freeze
    REQUIRED_PROPERTY_KEYS = %i[key owner_email address_line_1 town_city county postcode country property_description bedrooms sale_status asking_price].freeze
    REQUIRED_PROPERTY_BATCH_KEYS = %i[key_prefix count owner_emails sale_status].freeze
    REQUIRED_COUNT_BATCH_KEYS = %i[count].freeze

    def initialize(activity_generator: ScenarioActivityGenerator.new)
      @activity_generator = activity_generator
    end

    def validate!(payload)
      scenario = payload.deep_symbolize_keys

      validate_presence!(scenario, :key, :name)

      booking_configuration = normalize_booking_configuration(scenario[:booking_configuration] || {})
      admins = normalize_admins(Array(scenario[:admins]))
      users = normalize_users(Array(scenario[:users]))
      properties = normalize_properties(expand_property_specs(scenario))
      property_index = properties.index_by { |property| property.fetch(:key) }
      admin_emails = admins.map { |admin| admin.fetch(:email) }
      user_emails = users.map { |user| user.fetch(:email) }

      validate_uniqueness!(admins, :email, "admin email")
      validate_uniqueness!(users, :email, "user email")
      validate_uniqueness!(properties, :key, "property key")

      properties.each do |property|
        next if user_emails.include?(property.fetch(:owner_email))

        raise ValidationError, "Property #{property.fetch(:key)} references missing owner email #{property.fetch(:owner_email)}"
      end

      photos = normalize_photos(Array(scenario[:photos]), property_index:)
      floor_plans = normalize_floor_plans(Array(scenario[:floor_plans]), property_index:)
      property_documents = normalize_property_documents(Array(scenario[:property_documents]), property_index:)
      availability_windows = normalize_availability_windows(
        expand_availability_window_specs(
          Array(scenario[:availability_windows]),
          Array(scenario[:availability_window_batches]),
          properties: properties
        ),
        property_index:
      )
      appointments = normalize_appointments(
        expand_appointment_specs(
          Array(scenario[:appointments]),
          Array(scenario[:appointment_batches]),
          properties: properties,
          default_duration_minutes: booking_configuration.fetch(:slot_duration_minutes)
        ),
        property_index:,
        admin_emails:,
        default_duration_minutes: booking_configuration.fetch(:slot_duration_minutes)
      )
      enquiries = normalize_enquiries(
        expand_enquiry_specs(
          Array(scenario[:enquiries]),
          Array(scenario[:enquiry_batches]),
          properties: properties
        ),
        property_index:,
        admin_emails:
      )
      offers = normalize_offers(
        expand_offer_specs(
          Array(scenario[:offers]),
          Array(scenario[:offer_batches]),
          properties: properties
        ),
        property_index:,
        admin_emails:
      )
      rental_applications = normalize_rental_applications(
        expand_rental_application_specs(
          Array(scenario[:rental_applications]),
          Array(scenario[:rental_application_batches]),
          properties: properties
        ),
        property_index:,
        admin_emails:
      )

      {
        key: scenario.fetch(:key),
        name: scenario.fetch(:name),
        description: scenario[:description].to_s,
        qa: normalize_qa_metadata(scenario[:qa] || {}),
        booking_configuration:,
        admins:,
        users:,
        properties:,
        photos:,
        floor_plans:,
        property_documents:,
        availability_windows:,
        appointments:,
        enquiries:,
        offers:,
        rental_applications:
      }
    end

    def preview(payload)
      normalized = validate!(payload)

      {
        key: normalized.fetch(:key),
        name: normalized.fetch(:name),
        description: normalized.fetch(:description),
        qa: normalized.fetch(:qa).merge(expected_counts: expected_counts(normalized)),
        admin_count: normalized.fetch(:admins).count,
        user_count: normalized.fetch(:users).count,
        property_count: normalized.fetch(:properties).count,
        photo_count: normalized.fetch(:photos).count,
        floor_plan_count: normalized.fetch(:floor_plans).count,
        property_document_count: normalized.fetch(:property_documents).count,
        availability_window_count: normalized.fetch(:availability_windows).count,
        appointment_count: normalized.fetch(:appointments).count,
        appointment_statuses: normalized.fetch(:appointments).group_by { |appointment| appointment.fetch(:status) }.transform_values(&:count),
        enquiry_count: normalized.fetch(:enquiries).count,
        enquiry_statuses: normalized.fetch(:enquiries).group_by { |enquiry| enquiry.fetch(:status) }.transform_values(&:count),
        offer_count: normalized.fetch(:offers).count,
        offer_statuses: normalized.fetch(:offers).group_by { |offer| offer.fetch(:status) }.transform_values(&:count),
        rental_application_count: normalized.fetch(:rental_applications).count,
        rental_application_statuses: normalized.fetch(:rental_applications).group_by { |application| application.fetch(:status) }.transform_values(&:count)
      }
    end

    private

    attr_reader :activity_generator

    def normalize_qa_metadata(metadata)
      payload = metadata.deep_symbolize_keys
      family = payload.fetch(:family, "happy_path")
      raise ValidationError, "Unsupported scenario family #{family.inspect}" unless SCENARIO_FAMILIES.include?(family)

      complexity = payload.fetch(:complexity, "foundational")
      raise ValidationError, "Unsupported complexity #{complexity.inspect}" unless COMPLEXITY_LEVELS.include?(complexity)

      {
        family:,
        intended_journey: payload.fetch(:intended_journey, "General QA walkthrough").to_s,
        complexity:,
        risk_type: payload.fetch(:risk_type, "workflow").to_s,
        locale_coverage: Array(payload.fetch(:locale_coverage, ["en"])).map(&:to_s),
        trainer_notes: Array(payload[:trainer_notes]).map(&:to_s).reject(&:blank?),
        expected_assertions: Array(payload[:expected_assertions]).map(&:to_s).reject(&:blank?),
        quick_reset: ActiveModel::Type::Boolean.new.cast(payload.fetch(:quick_reset, false))
      }
    end

    def validate_presence!(hash, *keys)
      keys.each do |key|
        next if hash[key].present?

        raise ValidationError, "Missing required scenario key: #{key}"
      end
    end

    def normalize_booking_configuration(configuration)
      slot_duration_minutes = Integer(configuration.fetch(:slot_duration_minutes, BookingConfiguration.current.slot_duration_minutes))
      validate_supported_duration!(slot_duration_minutes, label: "Booking configuration slot duration")

      {
        slot_duration_minutes:,
        booking_window_days: Integer(configuration.fetch(:booking_window_days, 21)),
        lead_time_hours: Integer(configuration.fetch(:lead_time_hours, 4)),
        buffer_minutes: Integer(configuration.fetch(:buffer_minutes, 15)),
        office_opens_at: configuration.fetch(:office_opens_at, "09:00"),
        office_closes_at: configuration.fetch(:office_closes_at, "18:00"),
        open_weekdays: Array(configuration.fetch(:open_weekdays, [1, 2, 3, 4, 5, 6])).map(&:to_i)
      }
    end

    def normalize_admins(admins)
      admins.map do |admin|
        {
          email: admin.fetch(:email),
          password: admin.fetch(:password, "secret"),
          password_confirmation: admin.fetch(:password_confirmation, admin.fetch(:password, "secret")),
          language: admin.fetch(:language, "en")
        }
      end
    end

    def normalize_users(users)
      users.map do |user|
        {
          first_name: user.fetch(:first_name),
          last_name: user.fetch(:last_name),
          mobile_number: user.fetch(:mobile_number),
          email: user.fetch(:email),
          password: user.fetch(:password, "secret"),
          password_confirmation: user.fetch(:password_confirmation, user.fetch(:password, "secret")),
          language: user.fetch(:language, "en"),
          terms_of_service: true
        }
      end
    end

    def normalize_properties(properties)
      properties.map do |property|
        validate_presence!(property, *REQUIRED_PROPERTY_KEYS)
        chronology = chronology_for(property)
        property_type = property.fetch(:property_type, "House")
        unless Property::PROPERTY_TYPES.include?(property_type)
          raise ValidationError, "Unsupported property type #{property_type.inspect} for property #{property.fetch(:key)}"
        end

        {
          key: property.fetch(:key),
          owner_email: property.fetch(:owner_email),
          address_line_1: property.fetch(:address_line_1),
          address_line_2: property.fetch(:address_line_2, ""),
          town_city: property.fetch(:town_city),
          county: property.fetch(:county),
          postcode: property.fetch(:postcode),
          country: property.fetch(:country),
          property_description: property.fetch(:property_description),
          bedrooms: Integer(property.fetch(:bedrooms)),
          bathrooms: Integer(property.fetch(:bathrooms, 1)),
          property_type: property_type,
          listing_tagline: property[:listing_tagline],
          sale_status: property.fetch(:sale_status),
          asking_price: Integer(property.fetch(:asking_price)),
          featured: ActiveModel::Type::Boolean.new.cast(property.fetch(:featured, false)),
          listing_state: property.fetch(:listing_state, "published"),
          tenure: property[:tenure],
          council_tax_band: property[:council_tax_band],
          furnishing: property[:furnishing],
          available_from: property[:available_from].present? ? parse_date!(property[:available_from]) : nil,
          parking: property[:parking],
          outdoor_space: property[:outdoor_space],
          floor_area_sq_ft: property[:floor_area_sq_ft].present? ? Integer(property[:floor_area_sq_ft]) : nil,
          deposit_amount: property[:deposit_amount].present? ? Integer(property[:deposit_amount]) : nil,
          pets_allowed: ActiveModel::Type::Boolean.new.cast(property.fetch(:pets_allowed, false)),
          service_charge_amount: property[:service_charge_amount].present? ? Integer(property[:service_charge_amount]) : nil,
          lease_length_years: property[:lease_length_years].present? ? Integer(property[:lease_length_years]) : nil,
          year_built: chronology.fetch(:year_built),
          refurbished_year: chronology[:refurbished_year],
          created_at: property[:created_at].present? ? parse_time!(property[:created_at]) : nil,
          updated_at: property[:updated_at].present? ? parse_time!(property[:updated_at]) : nil,
          published_at: property[:published_at].present? ? parse_time!(property[:published_at]) : nil
        }
      end
    end

    def expand_property_specs(scenario)
      properties = Array(scenario[:properties]).map { |property| property.deep_symbolize_keys }
      property_batches = Array(scenario[:property_batches]).map { |batch| batch.deep_symbolize_keys }
      return properties if property_batches.empty?

      property_batches.each_with_object(properties) do |batch, expanded_properties|
        validate_presence!(batch, *REQUIRED_PROPERTY_BATCH_KEYS)

        key_prefix = batch.fetch(:key_prefix).to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "")
        raise ValidationError, "Property batch key prefix cannot be blank" if key_prefix.blank?

        count = Integer(batch.fetch(:count))
        raise ValidationError, "Property batch #{key_prefix} count must be greater than zero" if count <= 0

        owner_emails = Array(batch.fetch(:owner_emails)).map(&:to_s).reject(&:blank?)
        raise ValidationError, "Property batch #{key_prefix} must include at least one owner email" if owner_emails.empty?

        sale_status = batch.fetch(:sale_status)
        raise ValidationError, "Unsupported property batch sale status #{sale_status.inspect}" unless Property::SALE_STATUS.include?(sale_status)

        listing_state = batch.fetch(:listing_state, "published")
        raise ValidationError, "Unsupported property batch listing state #{listing_state.inspect}" unless Property::LISTING_STATES.include?(listing_state)

        featured = batch.key?(:featured) ? ActiveModel::Type::Boolean.new.cast(batch[:featured]) : nil
        random_seed = Integer(batch.fetch(:random_seed, 0))
        generator = PropertyBlueprintGenerator.new(random: Random.new(random_seed))
        overrides = normalize_property_batch_overrides(batch[:overrides], key_prefix:)

        generator.build_batch(count:, sale_status:, featured:).each_with_index do |blueprint, index|
          sequence = index + 1
          generated_key = "#{key_prefix}_#{format('%03d', sequence)}"

          expanded_properties << blueprint.except(:prompt_context).merge(
            key: generated_key,
            owner_email: owner_emails[index % owner_emails.length],
            listing_state:
          ).merge(overrides.fetch(generated_key, {}))
        end
      end
    end

    def normalize_property_batch_overrides(overrides, key_prefix:)
      Array(overrides).each_with_object({}) do |entry, normalized|
        entry = entry.deep_symbolize_keys
        key = entry[:key].to_s

        if key.blank? && entry[:sequence].present?
          key = "#{key_prefix}_#{format('%03d', Integer(entry[:sequence]))}"
        end

        raise ValidationError, "Property batch #{key_prefix} override must include key or sequence" if key.blank?
        raise ValidationError, "Property batch #{key_prefix} override key #{key.inspect} must start with #{key_prefix}_" unless key.start_with?("#{key_prefix}_")
        raise ValidationError, "Property batch #{key_prefix} contains duplicate override for #{key}" if normalized.key?(key)

        normalized[key] = entry.except(:key, :sequence)
      end
    end

    def chronology_for(property)
      generator = PropertyChronologyGenerator.new(random: Random.new(chronology_seed_for(property)))
      generator.generate(
        property_type: property.fetch(:property_type, "House"),
        sale_status: property.fetch(:sale_status),
        year_built: property[:year_built],
        refurbished_year: property[:refurbished_year]
      )
    end

    def chronology_seed_for(property)
      seed_source = [
        property[:key],
        property[:property_type],
        property[:town_city],
        property[:sale_status]
      ].join(":")

      Zlib.crc32(seed_source)
    end

    def expand_availability_window_specs(explicit_specs, batches, properties:)
      expanded = explicit_specs.map { |spec| spec.deep_symbolize_keys }
      return expanded if batches.empty?

      batches.each do |batch|
        batch = batch.deep_symbolize_keys
        selected_properties = select_batch_properties!(batch, properties, label: "availability window batch")

        expanded.concat(
          activity_generator.availability_windows(
            properties: selected_properties,
            start_day_offset: Integer(batch.fetch(:start_day_offset, 10)),
            start_time: batch.fetch(:start_time, "09:00"),
            duration_minutes: Integer(batch.fetch(:duration_minutes, 360)),
            cadence_days: Integer(batch.fetch(:cadence_days, 1)),
            kind: batch.fetch(:kind, "open"),
            capacity: Integer(batch.fetch(:capacity, 1)),
            label_prefix: batch.fetch(:label_prefix, "Generated viewing availability")
          )
        )
      end

      expanded
    end

    def expand_appointment_specs(explicit_specs, batches, properties:, default_duration_minutes:)
      expanded = explicit_specs.map { |spec| spec.deep_symbolize_keys }
      return expanded if batches.empty?

      batches.each do |batch|
        batch = batch.deep_symbolize_keys
        validate_presence!(batch, *REQUIRED_COUNT_BATCH_KEYS)
        selected_properties = select_batch_properties!(batch, properties, label: "appointment batch")

        expanded.concat(
          activity_generator.appointments(
            properties: selected_properties,
            count: Integer(batch.fetch(:count)),
            assigned_admin_email: batch[:assigned_admin_email],
            duration_minutes: Integer(batch.fetch(:duration_minutes, default_duration_minutes)),
            status_cycle: Array(batch.fetch(:status_cycle, %w[pending confirmed completed])),
            start_day_offset: Integer(batch.fetch(:start_day_offset, 8)),
            start_time: batch.fetch(:start_time, "09:00"),
            cadence_hours: Integer(batch.fetch(:cadence_hours, 2))
          )
        )
      end

      expanded
    end

    def expand_enquiry_specs(explicit_specs, batches, properties:)
      expanded = explicit_specs.map { |spec| spec.deep_symbolize_keys }
      return expanded if batches.empty?

      batches.each do |batch|
        batch = batch.deep_symbolize_keys
        validate_presence!(batch, *REQUIRED_COUNT_BATCH_KEYS)
        selected_properties = select_batch_properties!(batch, properties, label: "enquiry batch")

        expanded.concat(
          activity_generator.enquiries(
            properties: selected_properties,
            count: Integer(batch.fetch(:count)),
            assigned_admin_email: batch[:assigned_admin_email],
            status_cycle: Array(batch.fetch(:status_cycle, %w[new contacted qualified])),
            source_type_cycle: Array(batch.fetch(:source_type_cycle, %w[general_enquiry brochure_request]))
          )
        )
      end

      expanded
    end

    def expand_offer_specs(explicit_specs, batches, properties:)
      expanded = explicit_specs.map { |spec| spec.deep_symbolize_keys }
      return expanded if batches.empty?

      batches.each do |batch|
        batch = batch.deep_symbolize_keys
        validate_presence!(batch, *REQUIRED_COUNT_BATCH_KEYS)
        selected_properties = select_batch_properties!(batch, properties, label: "offer batch")

        expanded.concat(
          activity_generator.offers(
            properties: selected_properties,
            count: Integer(batch.fetch(:count)),
            assigned_admin_email: batch[:assigned_admin_email],
            status_cycle: Array(batch.fetch(:status_cycle, %w[received accepted rejected withdrawn]))
          )
        )
      end

      expanded
    end

    def expand_rental_application_specs(explicit_specs, batches, properties:)
      expanded = explicit_specs.map { |spec| spec.deep_symbolize_keys }
      return expanded if batches.empty?

      batches.each do |batch|
        batch = batch.deep_symbolize_keys
        validate_presence!(batch, *REQUIRED_COUNT_BATCH_KEYS)
        selected_properties = select_batch_properties!(batch, properties, label: "rental application batch")

        expanded.concat(
          activity_generator.rental_applications(
            properties: selected_properties,
            count: Integer(batch.fetch(:count)),
            assigned_admin_email: batch[:assigned_admin_email],
            status_cycle: Array(batch.fetch(:status_cycle, %w[received referencing approved rejected withdrawn]))
          )
        )
      end

      expanded
    end

    def select_batch_properties!(batch, properties, label:)
      selected = properties

      if batch[:property_keys].present?
        requested_keys = Array(batch[:property_keys]).map(&:to_s)
        selected = selected.select { |property| requested_keys.include?(property.fetch(:key).to_s) }
      end

      if batch[:property_key_prefixes].present?
        prefixes = Array(batch[:property_key_prefixes]).map(&:to_s)
        selected = selected.select { |property| prefixes.any? { |prefix| property.fetch(:key).to_s.start_with?(prefix) } }
      end

      if batch[:sale_status].present?
        selected = selected.select { |property| property.fetch(:sale_status) == batch.fetch(:sale_status) }
      end

      if batch[:listing_states].present?
        listing_states = Array(batch[:listing_states]).map(&:to_s)
        selected = selected.select { |property| listing_states.include?(property.fetch(:listing_state).to_s) }
      end

      raise ValidationError, "No properties matched #{label}" if selected.empty?

      selected.sort_by { |property| property.fetch(:key).to_s }
    end

    def normalize_photos(photos, property_index:)
      photos.map do |photo|
        property_key = photo.fetch(:property_key)
        raise ValidationError, "Photo references unknown property key #{property_key}" unless property_index.key?(property_key)

        {
          property_key:,
          image_filename: photo.fetch(:image_filename),
          caption: photo[:caption],
          position: Integer(photo.fetch(:position, 0)),
          primary: ActiveModel::Type::Boolean.new.cast(photo.fetch(:primary, false))
        }
      end
    end

    def normalize_floor_plans(floor_plans, property_index:)
      floor_plans.map do |floor_plan|
        property_key = floor_plan.fetch(:property_key)
        raise ValidationError, "Floor plan references unknown property key #{property_key}" unless property_index.key?(property_key)

        {
          property_key:,
          floor_plans: floor_plan.fetch(:floor_plans),
          label: floor_plan[:label],
          position: Integer(floor_plan.fetch(:position, 0))
        }
      end
    end

    def normalize_property_documents(property_documents, property_index:)
      property_documents.map do |document|
        property_key = document.fetch(:property_key)
        raise ValidationError, "Property document references unknown property key #{property_key}" unless property_index.key?(property_key)

        category = document.fetch(:category, "brochure")
        raise ValidationError, "Unsupported property document category #{category.inspect}" unless PropertyDocument::CATEGORIES.include?(category)

        visibility = document.fetch(:visibility, "private")
        raise ValidationError, "Unsupported property document visibility #{visibility.inspect}" unless PropertyDocument::VISIBILITIES.include?(visibility)

        {
          property_key:,
          title: document.fetch(:title),
          file_name: document.fetch(:file_name),
          category:,
          visibility:,
          position: Integer(document.fetch(:position, 0))
        }
      end
    end

    def normalize_availability_windows(windows, property_index:)
      windows.map do |window|
        property_key = window.fetch(:property_key)
        raise ValidationError, "Availability window references unknown property key #{property_key}" unless property_index.key?(property_key)

        {
          property_key:,
          starts_at: parse_time!(window.fetch(:starts_at)),
          ends_at: parse_time!(window.fetch(:ends_at)),
          kind: window.fetch(:kind, "open"),
          capacity: Integer(window.fetch(:capacity, 1)),
          label: window[:label],
          notes: window[:notes]
        }
      end
    end

    def normalize_appointments(appointments, property_index:, admin_emails:, default_duration_minutes:)
      appointments.map do |appointment|
        property_key = appointment.fetch(:property_key)
        raise ValidationError, "Appointment references unknown property key #{property_key}" unless property_index.key?(property_key)

        assigned_admin_email = appointment[:assigned_admin_email]
        if assigned_admin_email.present? && !admin_emails.include?(assigned_admin_email)
          raise ValidationError, "Appointment references unknown admin email #{assigned_admin_email}"
        end

        status = appointment.fetch(:status, "pending")
        unless Appointment::STATUSES.include?(status)
          raise ValidationError, "Unsupported appointment status #{status.inspect}"
        end

        requested_time = parse_time!(appointment.fetch(:requested_time))
        duration_minutes = Integer(appointment.fetch(:duration_minutes, default_duration_minutes))
        validate_supported_duration!(duration_minutes, label: "Appointment duration")

        {
          property_key:,
          assigned_admin_email:,
          customer_name: appointment.fetch(:customer_name),
          customer_email: appointment.fetch(:customer_email),
          customer_phone: appointment[:customer_phone],
          requested_time:,
          scheduled_at: parse_time!(appointment.fetch(:scheduled_at, requested_time)),
          duration_minutes:,
          status:,
          visit_outcome: appointment[:visit_outcome],
          notes: appointment[:notes],
          internal_notes: appointment[:internal_notes]
        }
      end
    end

    def normalize_enquiries(enquiries, property_index:, admin_emails:)
      enquiries.map do |enquiry|
        property_key = enquiry.fetch(:property_key)
        raise ValidationError, "Enquiry references unknown property key #{property_key}" unless property_index.key?(property_key)

        assigned_admin_email = enquiry[:assigned_admin_email]
        if assigned_admin_email.present? && !admin_emails.include?(assigned_admin_email)
          raise ValidationError, "Enquiry references unknown admin email #{assigned_admin_email}"
        end

        status = enquiry.fetch(:status, "new")
        unless Enquiry::STATUSES.include?(status)
          raise ValidationError, "Unsupported enquiry status #{status.inspect}"
        end

        source_type = enquiry.fetch(:source_type, "general_enquiry")
        unless Enquiry::SOURCE_TYPES.include?(source_type)
          raise ValidationError, "Unsupported enquiry source #{source_type.inspect}"
        end

        created_at, updated_at = parse_activity_timestamps!(enquiry, label: "Enquiry")

        {
          property_key:,
          assigned_admin_email:,
          customer_name: enquiry.fetch(:customer_name),
          customer_email: enquiry[:customer_email],
          customer_phone: enquiry[:customer_phone],
          source_type:,
          message: enquiry.fetch(:message),
          status:,
          internal_notes: enquiry[:internal_notes],
          spam: ActiveModel::Type::Boolean.new.cast(enquiry.fetch(:spam, false)),
          spam_reason: enquiry[:spam_reason],
          allow_invalid: ActiveModel::Type::Boolean.new.cast(enquiry.fetch(:allow_invalid, false)),
          created_at:,
          updated_at:
        }
      end
    end

    def normalize_offers(offers, property_index:, admin_emails:)
      offers.map do |offer|
        property_key = offer.fetch(:property_key)
        raise ValidationError, "Offer references unknown property key #{property_key}" unless property_index.key?(property_key)

        assigned_admin_email = offer[:assigned_admin_email]
        if assigned_admin_email.present? && !admin_emails.include?(assigned_admin_email)
          raise ValidationError, "Offer references unknown admin email #{assigned_admin_email}"
        end

        status = offer.fetch(:status, "received")
        raise ValidationError, "Unsupported offer status #{status.inspect}" unless Offer::STATUSES.include?(status)

        created_at, updated_at = parse_activity_timestamps!(offer, label: "Offer")

        {
          property_key:,
          assigned_admin_email:,
          buyer_name: offer.fetch(:buyer_name),
          buyer_email: offer.fetch(:buyer_email),
          buyer_phone: offer.fetch(:buyer_phone),
          amount: Integer(offer.fetch(:amount)),
          status:,
          chain_position: offer[:chain_position],
          notes: offer[:notes],
          internal_notes: offer[:internal_notes],
          created_at:,
          updated_at:
        }
      end
    end

    def normalize_rental_applications(applications, property_index:, admin_emails:)
      applications.map do |application|
        property_key = application.fetch(:property_key)
        raise ValidationError, "Rental application references unknown property key #{property_key}" unless property_index.key?(property_key)

        assigned_admin_email = application[:assigned_admin_email]
        if assigned_admin_email.present? && !admin_emails.include?(assigned_admin_email)
          raise ValidationError, "Rental application references unknown admin email #{assigned_admin_email}"
        end

        status = application.fetch(:status, "received")
        raise ValidationError, "Unsupported rental application status #{status.inspect}" unless RentalApplication::STATUSES.include?(status)

        created_at, updated_at = parse_activity_timestamps!(application, label: "Rental application")

        {
          property_key:,
          assigned_admin_email:,
          applicant_name: application.fetch(:applicant_name),
          applicant_email: application.fetch(:applicant_email),
          applicant_phone: application.fetch(:applicant_phone),
          move_in_date: parse_date!(application.fetch(:move_in_date)),
          status:,
          guarantor_required: ActiveModel::Type::Boolean.new.cast(application.fetch(:guarantor_required, false)),
          guarantor_available: ActiveModel::Type::Boolean.new.cast(application.fetch(:guarantor_available, false)),
          affordability_notes: application[:affordability_notes],
          notes: application[:notes],
          internal_notes: application[:internal_notes],
          created_at:,
          updated_at:
        }
      end
    end

    def validate_uniqueness!(records, key, label)
      values = records.map { |record| record.fetch(key) }
      duplicates = values.group_by(&:itself).select { |_value, entries| entries.size > 1 }.keys
      return if duplicates.empty?

      raise ValidationError, "Duplicate #{label.pluralize}: #{duplicates.join(', ')}"
    end

    def validate_supported_duration!(value, label:)
      return if BookingConfiguration::SUPPORTED_SLOT_DURATIONS.include?(value)

      raise ValidationError, "#{label} must be one of #{BookingConfiguration::SUPPORTED_SLOT_DURATIONS.join(', ')} minutes"
    end

    def parse_time!(value)
      relative = parse_relative_time(value)
      return relative if relative.present?

      return value.in_time_zone if value.respond_to?(:in_time_zone)

      parsed = Time.zone.parse(value.to_s)
      raise ValidationError, "Could not parse datetime #{value.inspect}" if parsed.blank?

      parsed
    end

    def parse_date!(value)
      relative = parse_relative_date(value)
      return relative if relative.present?

      return value if value.is_a?(Date) && !value.is_a?(Time)
      return value.in_time_zone.to_date if value.respond_to?(:in_time_zone)

      parsed = Date.parse(value.to_s)
      raise ValidationError, "Could not parse date #{value.inspect}" if parsed.blank?

      parsed
    rescue ArgumentError
      raise ValidationError, "Could not parse date #{value.inspect}"
    end

    def parse_activity_timestamps!(attributes, label:)
      created_at = attributes[:created_at].present? ? parse_time!(attributes[:created_at]) : nil
      updated_at = attributes[:updated_at].present? ? parse_time!(attributes[:updated_at]) : nil
      updated_at ||= created_at if created_at.present?

      if created_at.present? && updated_at.present? && updated_at < created_at
        raise ValidationError, "#{label} updated_at cannot be earlier than created_at"
      end

      [created_at, updated_at]
    end

    def parse_relative_time(value)
      match = value.to_s.strip.match(/\Atoday(?:(?<sign>[+-])(?<days>\d+)d)?\s+(?<hour>\d{2}):(?<minute>\d{2})\z/i)
      return nil unless match

      offset_days = match[:days].to_i
      offset_days *= -1 if match[:sign] == "-"
      target_date = Date.current + offset_days

      Time.zone.local(target_date.year, target_date.month, target_date.day, match[:hour].to_i, match[:minute].to_i)
    end

    def parse_relative_date(value)
      match = value.to_s.strip.match(/\Atoday(?:(?<sign>[+-])(?<days>\d+)d)?\z/i)
      return nil unless match

      offset_days = match[:days].to_i
      offset_days *= -1 if match[:sign] == "-"

      Date.current + offset_days
    end

    def expected_counts(normalized)
      {
        admins: normalized.fetch(:admins).count,
        users: normalized.fetch(:users).count,
        properties: normalized.fetch(:properties).count,
        photos: normalized.fetch(:photos).count,
        floor_plans: normalized.fetch(:floor_plans).count,
        property_documents: normalized.fetch(:property_documents).count,
        availability_windows: normalized.fetch(:availability_windows).count,
        appointments: normalized.fetch(:appointments).count,
        enquiries: normalized.fetch(:enquiries).count,
        offers: normalized.fetch(:offers).count,
        rental_applications: normalized.fetch(:rental_applications).count
      }
    end
  end
end
