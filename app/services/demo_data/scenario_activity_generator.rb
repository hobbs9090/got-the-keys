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

    def availability_windows(properties:, start_day_offset:, start_time:, duration_minutes:, cadence_days:, kind:, capacity:, label_prefix:, open_weekdays: BookingConfiguration::DEFAULT_OPEN_WEEKDAYS)
      properties.each_with_index.map do |property, index|
        starts_at = time_for(
          day_offset: start_day_offset + (index * cadence_days),
          time_string: shift_time(start_time, (index % 3) * 45),
          open_weekdays:
        )

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

    def appointments(properties:, count:, assigned_admin_email:, duration_minutes:, status_cycle:, start_day_offset:, start_time:, cadence_hours:, open_weekdays: BookingConfiguration::DEFAULT_OPEN_WEEKDAYS)
      build_records(properties:, count:) do |property, index|
        status = cycle_value(status_cycle, index)
        requested_time, scheduled_at = appointment_times_for(
          index: index,
          status: status,
          start_day_offset: start_day_offset,
          start_time: start_time,
          cadence_hours: cadence_hours,
          open_weekdays:
        )
        customer = contact_for(index, prefix: nil)

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
        created_at, updated_at = enquiry_timestamps_for(index, status)

        {
          property_key: property.fetch(:key),
          assigned_admin_email: assigned_admin_email,
          customer_name: contact.fetch(:name),
          customer_email: contact.fetch(:email),
          customer_phone: contact.fetch(:phone),
          source_type: source_type,
          message: enquiry_message_for(property, source_type),
          status: status,
          internal_notes: enquiry_internal_note_for(property, status),
          created_at:,
          updated_at:
        }
      end
    end

    def offers(properties:, count:, assigned_admin_email:, status_cycle:)
      build_records(properties:, count:) do |property, index|
        contact = contact_for(index, prefix: "buyer")
        status = cycle_value(status_cycle, index)
        created_at, updated_at = offer_timestamps_for(index, status)

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
          internal_notes: "Generated baseline offer seeded for negotiation and progression checks.",
          created_at:,
          updated_at:
        }
      end
    end

    def rental_applications(properties:, count:, assigned_admin_email:, status_cycle:)
      build_records(properties:, count:) do |property, index|
        contact = contact_for(index, prefix: "tenant")
        status = cycle_value(status_cycle, index)
        created_at, updated_at = rental_application_timestamps_for(index, status)

        {
          property_key: property.fetch(:key),
          assigned_admin_email: assigned_admin_email,
          applicant_name: contact.fetch(:name),
          applicant_email: contact.fetch(:email),
          applicant_phone: contact.fetch(:phone),
          move_in_date: [created_at.to_date + 12.days, Date.current + 14.days + index].max,
          status: status,
          guarantor_required: (index % 3).zero?,
          guarantor_available: (index % 4) != 1,
          affordability_notes: "Stable income and comfortable with the expected monthly commitment for this area.",
          notes: "Generated baseline tenancy application for admin workflow coverage.",
          internal_notes: "Useful for referencing, approval, and decline states during QA.",
          created_at:,
          updated_at:
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

    def time_for(day_offset:, time_string:, open_weekdays: BookingConfiguration::DEFAULT_OPEN_WEEKDAYS)
      hour, minute = time_string.split(":").map(&:to_i)
      target_date = open_day_for(day_offset:, open_weekdays:)

      Time.zone.local(target_date.year, target_date.month, target_date.day, hour, minute)
    end

    def shift_time(time_string, offset_minutes)
      base_hour, base_minute = time_string.split(":").map(&:to_i)
      shifted_total = (base_hour * 60) + base_minute + offset_minutes

      format("%02d:%02d", shifted_total / 60, shifted_total % 60)
    end

    def appointment_times_for(index:, status:, start_day_offset:, start_time:, cadence_hours:, open_weekdays:)
      day_offset = start_day_offset + (index / 4)
      requested_time = time_for(
        day_offset:,
        time_string: shift_time(start_time, (index % 4) * cadence_hours * 60),
        open_weekdays:
      )

      case status
      when "rescheduled"
        [requested_time, shift_time_by_open_days(requested_time, day_offset: 1, open_weekdays:) + 30.minutes]
      when "completed"
        completed_time = shift_time_by_open_days(requested_time, day_offset: -18, open_weekdays:)
        [completed_time, completed_time]
      when "no_show"
        no_show_time = shift_time_by_open_days(requested_time, day_offset: -14, open_weekdays:)
        [no_show_time, no_show_time]
      when "cancelled"
        cancelled_time = shift_time_by_open_days(requested_time, day_offset: -4, open_weekdays:)
        [cancelled_time, cancelled_time]
      else
        [requested_time, requested_time]
      end
    end

    def open_day_for(day_offset:, open_weekdays:)
      weekdays = Array(open_weekdays).map(&:to_i)
      return Date.current + day_offset if weekdays.empty?

      direction = day_offset.negative? ? -1 : 1
      remaining = day_offset.abs
      target_date = Date.current

      until weekdays.include?(target_date.cwday)
        target_date += direction.days
      end

      while remaining.positive?
        target_date += direction.days
        next unless weekdays.include?(target_date.cwday)

        remaining -= 1
      end

      target_date
    end

    def shift_time_by_open_days(time, day_offset:, open_weekdays:)
      target_date = shift_date_by_open_days(time.to_date, day_offset:, open_weekdays:)

      Time.zone.local(target_date.year, target_date.month, target_date.day, time.hour, time.min)
    end

    def shift_date_by_open_days(date, day_offset:, open_weekdays:)
      weekdays = Array(open_weekdays).map(&:to_i)
      return date + day_offset if weekdays.empty?

      direction = day_offset.negative? ? -1 : 1
      remaining = day_offset.abs
      target_date = date

      until weekdays.include?(target_date.cwday)
        target_date += direction.days
      end

      while remaining.positive?
        target_date += direction.days
        next unless weekdays.include?(target_date.cwday)

        remaining -= 1
      end

      target_date
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

    def enquiry_timestamps_for(index, status)
      created_at = Time.zone.now - (index % 5).days - (10 + (index % 3)).hours

      updated_at =
        case status
        when "new"
          created_at
        when "contacted"
          created_at + 6.hours
        when "qualified"
          created_at + 1.day + 2.hours
        when "unqualified", "archived"
          created_at + 2.days + 1.hour
        else
          created_at
        end

      [created_at, [updated_at, Time.zone.now - 30.minutes].min]
    end

    def offer_timestamps_for(index, status)
      created_at = Time.zone.now - (6 + index).days - ((index % 4) + 1).hours

      updated_at =
        case status
        when "received"
          created_at
        when "accepted"
          created_at + 4.days + 3.hours
        when "rejected"
          created_at + 3.days + 5.hours
        when "withdrawn"
          created_at + 2.days + 4.hours
        when "completed"
          created_at + 12.days + 2.hours
        else
          created_at
        end

      [created_at, [updated_at, Time.zone.now - 45.minutes].min]
    end

    def rental_application_timestamps_for(index, status)
      created_at = Time.zone.now - (7 + index).days - ((index % 3) + 2).hours

      updated_at =
        case status
        when "received"
          created_at
        when "referencing"
          created_at + 2.days + 6.hours
        when "approved"
          created_at + 5.days + 2.hours
        when "rejected"
          created_at + 4.days + 1.hour
        when "withdrawn"
          created_at + 3.days + 4.hours
        else
          created_at
        end

      [created_at, [updated_at, Time.zone.now - 45.minutes].min]
    end
  end
end
