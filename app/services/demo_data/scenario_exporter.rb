module DemoData
  class ScenarioExporter
    def export
      property_keys = {}

      payload = {
        key: BookingConfiguration.current.active_demo_scenario_key.presence || "exported_snapshot",
        name: "Exported Snapshot",
        description: "Generated from the current application dataset on #{Time.current.iso8601}. Passwords are normalized to 'secret' on export.",
        qa: export_qa_metadata,
        booking_configuration: export_configuration,
        admins: Admin.order(:email).map { |admin| export_admin(admin) },
        users: User.order(:email).map { |user| export_user(user) },
        properties: Property.order(:id).map { |property| export_property(property, property_keys) },
        photos: Photo.order(:property_id, :position, :id).map { |photo| export_photo(photo, property_keys) },
        floor_plans: FloorPlan.order(:property_id, :position, :id).map { |floor_plan| export_floor_plan(floor_plan, property_keys) },
        property_documents: PropertyDocument.order(:property_id, :position, :id).map { |document| export_property_document(document, property_keys) },
        availability_windows: AvailabilityWindow.order(:starts_at).map { |window| export_window(window, property_keys) },
        appointments: Appointment.order(:scheduled_at, :created_at).map { |appointment| export_appointment(appointment, property_keys) },
        enquiries: Enquiry.order(:created_at, :id).map { |enquiry| export_enquiry(enquiry, property_keys) },
        offers: Offer.order(:created_at, :id).map { |offer| export_offer(offer, property_keys) },
        rental_applications: RentalApplication.order(:created_at, :id).map { |application| export_rental_application(application, property_keys) }
      }

      YAML.dump(payload.deep_stringify_keys)
    end

    private

    def export_configuration
      configuration = BookingConfiguration.current

      {
        slot_duration_minutes: configuration.slot_duration_minutes,
        lead_time_hours: configuration.lead_time_hours,
        buffer_minutes: configuration.buffer_minutes,
        office_opens_at: configuration.office_opens_at,
        office_closes_at: configuration.office_closes_at,
        open_weekdays: configuration.open_weekday_numbers
      }
    end

    def export_qa_metadata
      {
        family: "happy_path",
        intended_journey: "Import and replay the currently running dataset.",
        complexity: "intermediate",
        risk_type: "workflow",
        locale_coverage: AppSettings.available_languages,
        trainer_notes: ["Use this when you need a portable snapshot of the current environment."],
        expected_assertions: ["The imported scenario should reproduce the exported counts and seeded personas."],
        quick_reset: false
      }
    end

    def export_admin(admin)
      {
        email: admin.email,
        password: "secret",
        password_confirmation: "secret",
        language: admin.language
      }
    end

    def export_user(user)
      {
        first_name: user.first_name,
        last_name: user.last_name,
        mobile_number: user.mobile_number,
        email: user.email,
        password: "secret",
        password_confirmation: "secret",
        language: user.language
      }
    end

    def export_property(property, property_keys)
      key = property_keys[property.id] ||= "#{property.address_line_1.to_s.parameterize.presence || 'property'}-#{property.id}"

      {
        key:,
        owner_email: property.user.email,
        address_line_1: property.address_line_1,
        address_line_2: property.address_line_2,
        town_city: property.town_city,
        county: property.county,
        postcode: property.postcode,
        country: property.country,
        property_description: property.property_description,
        bedrooms: property.bedrooms,
        bathrooms: property.bathrooms,
        property_type: property.property_type,
        listing_tagline: property.listing_tagline,
        sale_status: property.sale_status,
        asking_price: property.asking_price,
        featured: property.featured,
        listing_state: property.listing_state,
        tenure: property.tenure,
        council_tax_band: property.council_tax_band,
        furnishing: property.furnishing,
        available_from: property.available_from,
        parking: property.parking,
        outdoor_space: property.outdoor_space,
        floor_area_sq_ft: property.floor_area_sq_ft,
        deposit_amount: property.deposit_amount,
        pets_allowed: property.pets_allowed,
        service_charge_amount: property.service_charge_amount,
        lease_length_years: property.lease_length_years,
        year_built: property.year_built,
        refurbished_year: property.refurbished_year,
        created_at: property.created_at.iso8601,
        updated_at: property.updated_at.iso8601,
        published_at: property.published_at&.iso8601
      }
    end

    def export_photo(photo, property_keys)
      {
        property_key: property_keys.fetch(photo.property_id),
        image_filename: photo.image_filename,
        caption: photo.caption,
        position: photo.position,
        primary: photo.primary
      }
    end

    def export_floor_plan(floor_plan, property_keys)
      {
        property_key: property_keys.fetch(floor_plan.property_id),
        floor_plans: floor_plan.floor_plans,
        label: floor_plan.label,
        position: floor_plan.position
      }
    end

    def export_property_document(document, property_keys)
      {
        property_key: property_keys.fetch(document.property_id),
        title: document.title,
        file_name: document.file_name,
        category: document.category,
        visibility: document.visibility,
        position: document.position
      }
    end

    def export_window(window, property_keys)
      {
        property_key: property_keys.fetch(window.property_id),
        starts_at: window.starts_at.iso8601,
        ends_at: window.ends_at.iso8601,
        kind: window.kind,
        capacity: window.capacity,
        label: window.label,
        notes: window.notes
      }
    end

    def export_appointment(appointment, property_keys)
      {
        property_key: property_keys.fetch(appointment.property_id),
        assigned_admin_email: appointment.admin&.email,
        customer_name: appointment.customer_name,
        customer_email: appointment.customer_email,
        customer_phone: appointment.customer_phone,
        requested_time: appointment.requested_time.iso8601,
        scheduled_at: appointment.scheduled_at.iso8601,
        duration_minutes: appointment.duration_minutes,
        status: appointment.status,
        visit_outcome: appointment.visit_outcome,
        notes: appointment.notes,
        internal_notes: appointment.internal_notes
      }
    end

    def export_enquiry(enquiry, property_keys)
      {
        property_key: property_keys.fetch(enquiry.property_id),
        assigned_admin_email: enquiry.admin&.email,
        customer_name: enquiry.customer_name,
        customer_email: enquiry.customer_email,
        customer_phone: enquiry.customer_phone,
        source_type: enquiry.source_type,
        message: enquiry.message,
        status: enquiry.status,
        internal_notes: enquiry.internal_notes,
        spam: enquiry.spam,
        spam_reason: enquiry.spam_reason,
        allow_invalid: enquiry.customer_email.present? && !enquiry.customer_email.match?(URI::MailTo::EMAIL_REGEXP),
        created_at: enquiry.created_at.iso8601,
        updated_at: enquiry.updated_at.iso8601
      }
    end

    def export_offer(offer, property_keys)
      {
        property_key: property_keys.fetch(offer.property_id),
        assigned_admin_email: offer.admin&.email,
        buyer_name: offer.buyer_name,
        buyer_email: offer.buyer_email,
        buyer_phone: offer.buyer_phone,
        amount: offer.amount,
        status: offer.status,
        chain_position: offer.chain_position,
        notes: offer.notes,
        internal_notes: offer.internal_notes,
        created_at: offer.created_at.iso8601,
        updated_at: offer.updated_at.iso8601
      }
    end

    def export_rental_application(application, property_keys)
      {
        property_key: property_keys.fetch(application.property_id),
        assigned_admin_email: application.admin&.email,
        applicant_name: application.applicant_name,
        applicant_email: application.applicant_email,
        applicant_phone: application.applicant_phone,
        move_in_date: application.move_in_date.iso8601,
        status: application.status,
        guarantor_required: application.guarantor_required,
        guarantor_available: application.guarantor_available,
        affordability_notes: application.affordability_notes,
        notes: application.notes,
        internal_notes: application.internal_notes,
        created_at: application.created_at.iso8601,
        updated_at: application.updated_at.iso8601
      }
    end
  end
end
