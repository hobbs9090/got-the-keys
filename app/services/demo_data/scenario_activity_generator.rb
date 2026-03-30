module DemoData
  class ScenarioActivityGenerator
    CONTACT_FIRST_NAMES = %w[
      Amelia
      Arthur
      Ava
      Benjamin
      Chloe
      Daniel
      Eleanor
      Ethan
      Freya
      George
      Grace
      Hannah
      Isla
      Jack
      Lily
      Lucas
      Mia
      Noah
      Olivia
      Samuel
    ].freeze

    CONTACT_LAST_NAMES = %w[
      Bailey
      Carter
      Dawson
      Ellis
      Foster
      Graham
      Harper
      Irving
      Jordan
      Kennedy
      Lawson
      Morgan
      Nolan
      Palmer
      Quinn
      Russell
      Sawyer
      Turner
      Walker
      Young
    ].freeze

    ENQUIRY_MESSAGE_TEMPLATES = {
      "brochure_request" => "Please send the brochure and let me know whether there is any flexibility around timing for a second viewing.",
      "valuation_request" => "We are comparing a few moves and would like a clearer sense of pricing, presentation expectations, and likely next steps.",
      "letting_enquiry" => "I am planning a move soon and want to confirm timing, furnishings, and whether the tenancy terms are straightforward.",
      "general_enquiry" => "We like the look of this listing and would love more detail on the layout, condition, and next available viewing options."
    }.freeze

    CHAIN_POSITIONS = [
      "First-time buyer",
      "Chain free",
      "Proceedable buyer with mortgage agreed",
      "Sale agreed and ready to move"
    ].freeze

    def availability_windows(properties:, start_day_offset:, start_time:, duration_minutes:, cadence_days:, kind:, capacity:, label_prefix:)
      properties.each_with_index.map do |property, index|
        starts_at = time_for(day_offset: start_day_offset + (index * cadence_days), time_string: shift_time(start_time, (index % 3) * 45))

        {
          property_key: property.fetch(:key),
          starts_at: starts_at,
          ends_at: starts_at + duration_minutes.minutes,
          kind: kind,
          capacity: capacity,
          label: "#{label_prefix} #{index + 1}"
        }
      end
    end

    def appointments(properties:, count:, assigned_admin_email:, duration_minutes:, status_cycle:, start_day_offset:, start_time:, cadence_hours:)
      build_records(properties:, count:) do |property, index|
        status = cycle_value(status_cycle, index)
        requested_time, scheduled_at = appointment_times_for(
          index: index,
          status: status,
          start_day_offset: start_day_offset,
          start_time: start_time,
          cadence_hours: cadence_hours
        )
        customer = contact_for(index, prefix: "viewer")

        {
          property_key: property.fetch(:key),
          assigned_admin_email: assigned_admin_email,
          customer_name: customer.fetch(:name),
          customer_email: customer.fetch(:email),
          customer_phone: customer.fetch(:phone),
          requested_time: requested_time,
          scheduled_at: scheduled_at,
          duration_minutes: duration_minutes,
          status: status,
          visit_outcome: appointment_outcome_for(status, index),
          notes: appointment_note_for(property, status),
          internal_notes: appointment_internal_note_for(property, status)
        }
      end
    end

    def enquiries(properties:, count:, assigned_admin_email:, status_cycle:, source_type_cycle:)
      build_records(properties:, count:) do |property, index|
        status = cycle_value(status_cycle, index)
        source_type = cycle_value(source_type_cycle, index)
        contact = contact_for(index, prefix: "lead")

        {
          property_key: property.fetch(:key),
          assigned_admin_email: assigned_admin_email,
          customer_name: contact.fetch(:name),
          customer_email: contact.fetch(:email),
          customer_phone: contact.fetch(:phone),
          source_type: source_type,
          message: enquiry_message_for(property, source_type),
          status: status,
          internal_notes: enquiry_internal_note_for(property, status)
        }
      end
    end

    def offers(properties:, count:, assigned_admin_email:, status_cycle:)
      build_records(properties:, count:) do |property, index|
        contact = contact_for(index, prefix: "buyer")
        status = cycle_value(status_cycle, index)

        {
          property_key: property.fetch(:key),
          assigned_admin_email: assigned_admin_email,
          buyer_name: contact.fetch(:name),
          buyer_email: contact.fetch(:email),
          buyer_phone: contact.fetch(:phone),
          amount: offer_amount_for(property, index),
          status: status,
          chain_position: cycle_value(CHAIN_POSITIONS, index),
          notes: "Keen on #{property.fetch(:town_city)} and ready to move quickly if the offer is accepted.",
          internal_notes: "Generated baseline offer seeded for negotiation and progression checks."
        }
      end
    end

    def rental_applications(properties:, count:, assigned_admin_email:, status_cycle:)
      build_records(properties:, count:) do |property, index|
        contact = contact_for(index, prefix: "tenant")
        status = cycle_value(status_cycle, index)

        {
          property_key: property.fetch(:key),
          assigned_admin_email: assigned_admin_email,
          applicant_name: contact.fetch(:name),
          applicant_email: contact.fetch(:email),
          applicant_phone: contact.fetch(:phone),
          move_in_date: Date.current + 18 + index,
          status: status,
          guarantor_required: (index % 3).zero?,
          guarantor_available: (index % 4) != 1,
          affordability_notes: "Stable income and comfortable with the expected monthly commitment for this area.",
          notes: "Generated baseline tenancy application for admin workflow coverage.",
          internal_notes: "Useful for referencing, approval, and decline states during QA."
        }
      end
    end

    private

    def build_records(properties:, count:)
      Array.new(count) do |index|
        property = properties.fetch(index % properties.length)
        yield property, index
      end
    end

    def cycle_value(values, index)
      values.fetch(index % values.length)
    end

    def contact_for(index, prefix:)
      first_name = CONTACT_FIRST_NAMES.fetch(index % CONTACT_FIRST_NAMES.length)
      last_name = CONTACT_LAST_NAMES.fetch((index / CONTACT_FIRST_NAMES.length + index) % CONTACT_LAST_NAMES.length)
      suffix = index >= CONTACT_FIRST_NAMES.length ? (index / CONTACT_FIRST_NAMES.length) + 1 : nil
      local_part = [prefix, first_name, last_name, suffix].compact.join(".").downcase

      {
        name: "#{first_name} #{last_name}",
        email: "#{local_part}@example.com",
        phone: "07700 #{format('%06d', 940_100 + index)}"
      }
    end

    def time_for(day_offset:, time_string:)
      hour, minute = time_string.split(":").map(&:to_i)
      target_date = Date.current + day_offset

      Time.zone.local(target_date.year, target_date.month, target_date.day, hour, minute)
    end

    def shift_time(time_string, offset_minutes)
      base_hour, base_minute = time_string.split(":").map(&:to_i)
      shifted_total = (base_hour * 60) + base_minute + offset_minutes

      format("%02d:%02d", shifted_total / 60, shifted_total % 60)
    end

    def appointment_times_for(index:, status:, start_day_offset:, start_time:, cadence_hours:)
      day_offset = start_day_offset + (index / 4)
      requested_time = time_for(day_offset:, time_string: shift_time(start_time, (index % 4) * cadence_hours * 60))

      case status
      when "rescheduled"
        [requested_time, requested_time + 1.day + 30.minutes]
      when "completed"
        [requested_time - 18.days, requested_time - 18.days]
      when "no_show"
        [requested_time - 10.days, requested_time - 10.days]
      when "cancelled"
        [requested_time - 4.days, requested_time - 4.days]
      else
        [requested_time, requested_time]
      end
    end

    def appointment_outcome_for(status, index)
      return nil unless status == "completed"

      cycle_value(Appointment::VISIT_OUTCOMES, index)
    end

    def appointment_note_for(property, status)
      case status
      when "pending"
        "Interested in the #{property.fetch(:property_type).downcase} and wants to confirm parking before visiting."
      when "confirmed"
        "Asked for a smooth handover on arrival and a little extra time for questions."
      when "rescheduled"
        "Needed to move the visit because of a work clash but still very interested."
      when "completed"
        "Visited recently and asked for follow-up information afterwards."
      when "no_show"
        "Mentioned possible travel delays on the day of the visit."
      else
        "Seeded baseline booking covering a realistic admin follow-up path."
      end
    end

    def appointment_internal_note_for(property, status)
      case status
      when "confirmed", "rescheduled"
        "Admin follow-up prepared with local context for #{property.fetch(:town_city)}."
      when "completed"
        "Generated completed viewing with documented next steps for seller reporting."
      when "no_show"
        "No arrival recorded and voicemail left after the missed slot."
      when "cancelled"
        "Cancelled after the customer shortlisted another property."
      else
        "Baseline generated appointment attached to #{property.fetch(:key)}."
      end
    end

    def enquiry_message_for(property, source_type)
      "#{ENQUIRY_MESSAGE_TEMPLATES.fetch(source_type)} This one in #{property.fetch(:town_city)} stood out because of the #{property.fetch(:property_type).downcase} layout."
    end

    def enquiry_internal_note_for(property, status)
      "Generated #{status} enquiry for #{property.fetch(:town_city)} to keep the baseline lead pipeline varied."
    end

    def offer_amount_for(property, index)
      factor = [0.94, 0.97, 0.99, 1.01].fetch(index % 4)
      amount = (property.fetch(:asking_price) * factor).round

      [[amount, 50_000].max, 2_500_000].min.round(-3)
    end
  end
end
