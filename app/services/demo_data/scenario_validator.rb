module DemoData
  class ScenarioValidator
    class ValidationError < StandardError; end

    REQUIRED_PROPERTY_KEYS = %i[key owner_email address_line_1 town_city county postcode country property_description bedrooms sale_status asking_price].freeze

    def validate!(payload)
      scenario = payload.deep_symbolize_keys

      validate_presence!(scenario, :key, :name)

      admins = normalize_admins(Array(scenario[:admins]))
      users = normalize_users(Array(scenario[:users]))
      properties = normalize_properties(Array(scenario[:properties]))
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
      availability_windows = normalize_availability_windows(Array(scenario[:availability_windows]), property_index:)
      appointments = normalize_appointments(
        Array(scenario[:appointments]),
        property_index:,
        admin_emails:,
        default_duration_minutes: scenario.dig(:booking_configuration, :slot_duration_minutes) || BookingConfiguration.current.slot_duration_minutes
      )
      enquiries = normalize_enquiries(
        Array(scenario[:enquiries]),
        property_index:,
        admin_emails:
      )
      offers = normalize_offers(
        Array(scenario[:offers]),
        property_index:,
        admin_emails:
      )
      rental_applications = normalize_rental_applications(
        Array(scenario[:rental_applications]),
        property_index:,
        admin_emails:
      )

      {
        key: scenario.fetch(:key),
        name: scenario.fetch(:name),
        description: scenario[:description].to_s,
        booking_configuration: normalize_booking_configuration(scenario[:booking_configuration] || {}),
        admins:,
        users:,
        properties:,
        photos:,
        floor_plans:,
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
        admin_count: normalized.fetch(:admins).count,
        user_count: normalized.fetch(:users).count,
        property_count: normalized.fetch(:properties).count,
        photo_count: normalized.fetch(:photos).count,
        floor_plan_count: normalized.fetch(:floor_plans).count,
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

    def validate_presence!(hash, *keys)
      keys.each do |key|
        next if hash[key].present?

        raise ValidationError, "Missing required scenario key: #{key}"
      end
    end

    def normalize_booking_configuration(configuration)
      {
        slot_duration_minutes: Integer(configuration.fetch(:slot_duration_minutes, 45)),
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
          property_type: property.fetch(:property_type, "House"),
          listing_tagline: property[:listing_tagline],
          sale_status: property.fetch(:sale_status),
          asking_price: Integer(property.fetch(:asking_price)),
          featured: ActiveModel::Type::Boolean.new.cast(property.fetch(:featured, false)),
          listing_state: property.fetch(:listing_state, "published"),
          tenure: property[:tenure],
          council_tax_band: property[:council_tax_band],
          furnishing: property[:furnishing],
          available_from: property[:available_from],
          parking: property[:parking],
          outdoor_space: property[:outdoor_space],
          epc_rating: property[:epc_rating],
          floor_area_sq_ft: property[:floor_area_sq_ft].present? ? Integer(property[:floor_area_sq_ft]) : nil,
          deposit_amount: property[:deposit_amount].present? ? Integer(property[:deposit_amount]) : nil,
          pets_allowed: ActiveModel::Type::Boolean.new.cast(property.fetch(:pets_allowed, false)),
          service_charge_amount: property[:service_charge_amount].present? ? Integer(property[:service_charge_amount]) : nil,
          lease_length_years: property[:lease_length_years].present? ? Integer(property[:lease_length_years]) : nil
        }
      end
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

        {
          property_key:,
          assigned_admin_email:,
          customer_name: appointment.fetch(:customer_name),
          customer_email: appointment.fetch(:customer_email),
          customer_phone: appointment[:customer_phone],
          requested_time:,
          scheduled_at: parse_time!(appointment.fetch(:scheduled_at, requested_time)),
          duration_minutes: Integer(appointment.fetch(:duration_minutes, default_duration_minutes)),
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
          allow_invalid: ActiveModel::Type::Boolean.new.cast(enquiry.fetch(:allow_invalid, false))
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
          internal_notes: offer[:internal_notes]
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

        {
          property_key:,
          assigned_admin_email:,
          applicant_name: application.fetch(:applicant_name),
          applicant_email: application.fetch(:applicant_email),
          applicant_phone: application.fetch(:applicant_phone),
          move_in_date: Date.parse(application.fetch(:move_in_date).to_s),
          status:,
          guarantor_required: ActiveModel::Type::Boolean.new.cast(application.fetch(:guarantor_required, false)),
          guarantor_available: ActiveModel::Type::Boolean.new.cast(application.fetch(:guarantor_available, false)),
          affordability_notes: application[:affordability_notes],
          notes: application[:notes],
          internal_notes: application[:internal_notes]
        }
      end
    end

    def validate_uniqueness!(records, key, label)
      values = records.map { |record| record.fetch(key) }
      duplicates = values.group_by(&:itself).select { |_value, entries| entries.size > 1 }.keys
      return if duplicates.empty?

      raise ValidationError, "Duplicate #{label.pluralize}: #{duplicates.join(', ')}"
    end

    def parse_time!(value)
      relative = parse_relative_time(value)
      return relative if relative.present?

      return value.in_time_zone if value.respond_to?(:in_time_zone)

      parsed = Time.zone.parse(value.to_s)
      raise ValidationError, "Could not parse datetime #{value.inspect}" if parsed.blank?

      parsed
    end

    def parse_relative_time(value)
      match = value.to_s.strip.match(/\Atoday(?:(?<sign>[+-])(?<days>\d+)d)?\s+(?<hour>\d{2}):(?<minute>\d{2})\z/i)
      return nil unless match

      offset_days = match[:days].to_i
      offset_days *= -1 if match[:sign] == "-"
      target_date = Date.current + offset_days

      Time.zone.local(target_date.year, target_date.month, target_date.day, match[:hour].to_i, match[:minute].to_i)
    end
  end
end
