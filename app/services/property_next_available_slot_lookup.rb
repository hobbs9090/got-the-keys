class PropertyNextAvailableSlotLookup
  def initialize(properties:, from: Time.current, configuration: BookingConfiguration.current)
    @properties = Array(properties).compact
    @from = from
    @configuration = configuration
  end

  def call(limit: 1)
    return {} if properties.empty?

    properties.each_with_object({}) do |property, slots_by_property_id|
      availability = AppointmentAvailability.new(
        property: property,
        configuration: configuration,
        from: from,
        availability_windows: availability_windows_by_property_id.fetch(property.id, []),
        blocking_appointments: blocking_appointments_by_property_id.fetch(property.id, [])
      )

      slots_by_property_id[property.id] = availability.next_slots(limit:).first
    end
  end

  private

  attr_reader :properties, :from, :configuration

  def property_ids
    @property_ids ||= properties.map(&:id)
  end

  def booking_window_end
    @booking_window_end ||= from + configuration.booking_window_days.days + 1.day
  end

  def availability_windows_by_property_id
    @availability_windows_by_property_id ||=
      AvailabilityWindow.where(property_id: property_ids).order(:starts_at).group_by(&:property_id)
  end

  def blocking_appointments_by_property_id
    @blocking_appointments_by_property_id ||=
      Appointment.blocking
        .where(property_id: property_ids, scheduled_at: (from - 1.day)..booking_window_end)
        .group_by(&:property_id)
  end
end
