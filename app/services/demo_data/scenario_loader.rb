module DemoData
  class ScenarioLoader
    def initialize(catalog: ScenarioCatalog.new, validator: ScenarioValidator.new, exporter: ScenarioExporter.new)
      @catalog = catalog
      @validator = validator
      @exporter = exporter
    end

    def scenarios
      catalog.all.map { |scenario| validator.preview(scenario) }
    end

    def preview(key)
      validator.preview(catalog.fetch!(key))
    end

    def preview_yaml(yaml_source)
      validator.preview(parse_yaml(yaml_source))
    end

    def apply_catalog!(key:, actor_email:)
      apply_payload!(validator.validate!(catalog.fetch!(key)), action_type: key == "baseline" ? "restore" : "apply", actor_email:, source: "catalog")
    end

    def apply_yaml!(yaml_source:, actor_email:)
      apply_payload!(validator.validate!(parse_yaml(yaml_source)), action_type: "import", actor_email:, source: "import")
    end

    def export
      exported = exporter.export

      DemoScenarioRun.create!(
        scenario_key: BookingConfiguration.current.active_demo_scenario_key,
        action_type: "export",
        initiated_by_email: nil,
        source: "export",
        summary_data: {
          exported_at: Time.current.iso8601,
          property_count: Property.count,
          appointment_count: Appointment.count,
          enquiry_count: Enquiry.count
        }
      )

      exported
    end

    private

    attr_reader :catalog, :validator, :exporter

    def parse_yaml(yaml_source)
      YAML.safe_load(yaml_source.to_s, permitted_classes: [Date, Time], aliases: false) || {}
    end

    def apply_payload!(payload, action_type:, actor_email:, source:)
      summary = nil

      ActiveRecord::Base.transaction do
        reset_demo_data!

        configuration = BookingConfiguration.create!(
          payload.fetch(:booking_configuration).merge(
            active_demo_scenario_key: payload.fetch(:key),
            last_demo_data_action_at: Time.current
          )
        )

        admins = create_admins(payload.fetch(:admins))
        users = create_users(payload.fetch(:users))
        properties = create_properties(payload.fetch(:properties), users:)
        create_photos(payload.fetch(:photos), properties:)
        create_floor_plans(payload.fetch(:floor_plans), properties:)
        create_property_documents(payload.fetch(:property_documents), properties:)
        create_availability_windows(payload.fetch(:availability_windows), properties:)
        create_appointments(payload.fetch(:appointments), properties:, admins:)
        create_enquiries(payload.fetch(:enquiries), properties:, admins:)
        create_offers(payload.fetch(:offers), properties:, admins:)
        create_rental_applications(payload.fetch(:rental_applications), properties:, admins:)

        summary = {
          name: payload.fetch(:name),
          description: payload.fetch(:description),
          admin_count: admins.size,
          user_count: users.size,
          property_count: properties.size,
          photo_count: Photo.count,
          floor_plan_count: FloorPlan.count,
          property_document_count: PropertyDocument.count,
          appointment_count: Appointment.count,
          enquiry_count: Enquiry.count,
          offer_count: Offer.count,
          rental_application_count: RentalApplication.count,
          active_demo_scenario_key: configuration.active_demo_scenario_key
        }

        DemoScenarioRun.create!(
          scenario_key: payload.fetch(:key),
          action_type:,
          initiated_by_email: actor_email,
          source:,
          summary_data: summary
        )
      end

      summary
    end

    def reset_demo_data!
      NotificationLog.delete_all
      AppointmentEvent.delete_all
      OfferEvent.delete_all
      RentalApplicationEvent.delete_all
      Appointment.delete_all
      Enquiry.delete_all
      Offer.delete_all
      RentalApplication.delete_all
      AvailabilityWindow.delete_all
      Photo.delete_all
      FloorPlan.delete_all
      PropertyDocument.delete_all
      AuditLog.delete_all
      Property.delete_all
      User.delete_all
      Admin.delete_all
      BookingConfiguration.delete_all
    end

    def create_admins(admin_specs)
      admin_specs.each_with_object({}) do |attributes, memo|
        memo[attributes.fetch(:email)] = Admin.create!(attributes)
      end
    end

    def create_users(user_specs)
      user_specs.each_with_object({}) do |attributes, memo|
        memo[attributes.fetch(:email)] = User.create!(attributes)
      end
    end

    def create_properties(property_specs, users:)
      property_specs.each_with_object({}) do |attributes, memo|
        owner = users.fetch(attributes.fetch(:owner_email))

        property = owner.properties.create!(
          attributes.except(:key, :owner_email, :created_at, :updated_at)
        )
        property.update_columns(
          {
            created_at: attributes[:created_at],
            updated_at: attributes[:updated_at]
          }.compact
        ) if attributes[:created_at].present? || attributes[:updated_at].present?

        memo[attributes.fetch(:key)] = property
      end
    end

    def create_availability_windows(window_specs, properties:)
      window_specs.each do |attributes|
        properties.fetch(attributes.fetch(:property_key)).availability_windows.create!(
          attributes.except(:property_key)
        )
      end
    end

    def create_photos(photo_specs, properties:)
      photo_specs.each do |attributes|
        properties.fetch(attributes.fetch(:property_key)).photos.create!(
          attributes.except(:property_key)
        )
      end
    end

    def create_floor_plans(floor_plan_specs, properties:)
      floor_plan_specs.each do |attributes|
        properties.fetch(attributes.fetch(:property_key)).floor_plans.create!(
          attributes.except(:property_key)
        )
      end
    end

    def create_property_documents(document_specs, properties:)
      document_specs.each do |attributes|
        properties.fetch(attributes.fetch(:property_key)).property_documents.create!(
          attributes.except(:property_key)
        )
      end
    end

    def create_appointments(appointment_specs, properties:, admins:)
      appointment_specs.each do |attributes|
        property = properties.fetch(attributes.fetch(:property_key))
        admin = attributes[:assigned_admin_email].present? ? admins.fetch(attributes.fetch(:assigned_admin_email)) : nil
        final_status = attributes.fetch(:status)
        requested_time = attributes.fetch(:requested_time)
        scheduled_at = attributes.fetch(:scheduled_at)

        appointment = property.appointments.create!(
          {
            admin:,
            customer_name: attributes.fetch(:customer_name),
            customer_email: attributes.fetch(:customer_email),
            customer_phone: attributes[:customer_phone],
            requested_time:,
            scheduled_at: requested_time,
            duration_minutes: attributes.fetch(:duration_minutes),
            notes: attributes[:notes],
            internal_notes: attributes[:internal_notes],
            status: "pending",
            visit_outcome: attributes[:visit_outcome]
          }.merge(skip_slot_validation: true)
        )

        next if final_status == "pending" && scheduled_at == requested_time && attributes[:visit_outcome].blank?

        appointment.update!(
          admin:,
          scheduled_at:,
          status: final_status,
          visit_outcome: attributes[:visit_outcome],
          notes: attributes[:notes],
          internal_notes: attributes[:internal_notes]
        )
      end
    end

    def create_enquiries(enquiry_specs, properties:, admins:)
      enquiry_specs.each do |attributes|
        property = properties.fetch(attributes.fetch(:property_key))
        admin = attributes[:assigned_admin_email].present? ? admins.fetch(attributes.fetch(:assigned_admin_email)) : nil

        Enquiry.create_seeded!(
          property:,
          admin:,
          allow_invalid: attributes.fetch(:allow_invalid, false),
          customer_name: attributes.fetch(:customer_name),
          customer_email: attributes[:customer_email],
          customer_phone: attributes[:customer_phone],
          source_type: attributes.fetch(:source_type),
          message: attributes.fetch(:message),
          status: attributes.fetch(:status),
          internal_notes: attributes[:internal_notes],
          spam: attributes.fetch(:spam, false),
          spam_reason: attributes[:spam_reason]
        )
      end
    end

    def create_offers(offer_specs, properties:, admins:)
      offer_specs.each do |attributes|
        property = properties.fetch(attributes.fetch(:property_key))
        admin = attributes[:assigned_admin_email].present? ? admins.fetch(attributes.fetch(:assigned_admin_email)) : nil
        final_status = attributes.fetch(:status)

        offer = property.offers.create!(
          admin:,
          buyer_name: attributes.fetch(:buyer_name),
          buyer_email: attributes.fetch(:buyer_email),
          buyer_phone: attributes.fetch(:buyer_phone),
          amount: attributes.fetch(:amount),
          status: "received",
          chain_position: attributes[:chain_position],
          notes: attributes[:notes],
          internal_notes: attributes[:internal_notes]
        )

        next if final_status == "received"

        offer.update!(
          admin:,
          status: final_status,
          chain_position: attributes[:chain_position],
          internal_notes: attributes[:internal_notes]
        )
      end
    end

    def create_rental_applications(application_specs, properties:, admins:)
      application_specs.each do |attributes|
        property = properties.fetch(attributes.fetch(:property_key))
        admin = attributes[:assigned_admin_email].present? ? admins.fetch(attributes.fetch(:assigned_admin_email)) : nil
        final_status = attributes.fetch(:status)

        application = property.rental_applications.create!(
          admin:,
          applicant_name: attributes.fetch(:applicant_name),
          applicant_email: attributes.fetch(:applicant_email),
          applicant_phone: attributes.fetch(:applicant_phone),
          move_in_date: attributes.fetch(:move_in_date),
          status: "received",
          guarantor_required: attributes.fetch(:guarantor_required, false),
          guarantor_available: attributes.fetch(:guarantor_available, false),
          affordability_notes: attributes[:affordability_notes],
          notes: attributes[:notes],
          internal_notes: attributes[:internal_notes]
        )

        next if final_status == "received"

        application.update!(
          admin:,
          status: final_status,
          guarantor_required: attributes.fetch(:guarantor_required, false),
          guarantor_available: attributes.fetch(:guarantor_available, false),
          affordability_notes: attributes[:affordability_notes],
          internal_notes: attributes[:internal_notes]
        )
      end
    end
  end
end
