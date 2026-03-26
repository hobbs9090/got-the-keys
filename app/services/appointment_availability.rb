class AppointmentAvailability
  Slot = Struct.new(:starts_at, :ends_at, :group_viewing, keyword_init: true) do
    def label
      base = "#{I18n.l(starts_at, format: :long)} to #{I18n.l(ends_at, format: :time_only)}"
      group_viewing ? "#{base} (group viewing)" : base
    end
  end

  def initialize(property:, configuration: BookingConfiguration.current, from: Time.current)
    @property = property
    @configuration = configuration
    @from = from
  end

  def next_slots(limit: 8, days_ahead: 21, excluding_appointment: nil)
    slots = []

    date_range(days_ahead).each do |date|
      windows_for(date).each do |window_start, window_end|
        cursor = [window_start, from].max

        while (cursor + slot_duration) <= window_end
          slot_end = cursor + slot_duration

          if slot_available?(cursor, duration_minutes: configuration.slot_duration_minutes, excluding_appointment:)
            slots << Slot.new(starts_at: cursor, ends_at: slot_end, group_viewing: group_viewing_window?(cursor, slot_end))
            return slots if slots.length >= limit
          end

          cursor += configuration.slot_duration_minutes.minutes
        end
      end
    end

    slots
  end

  def slot_available?(starts_at, duration_minutes:, excluding_appointment: nil)
    return false if starts_at.blank?

    ends_at = starts_at + duration_minutes.minutes
    return false if enforce_lead_time?(starts_at) && starts_at < minimum_bookable_time
    return false unless within_open_window?(starts_at, ends_at)
    return false if blackout_overlap?(starts_at, ends_at)
    return false if blocking_overlap?(starts_at, ends_at, excluding_appointment:)

    true
  end

  private

  attr_reader :property, :configuration, :from

  def slot_duration
    configuration.slot_duration_minutes.minutes
  end

  def minimum_bookable_time
    Time.current + configuration.lead_time_hours.hours
  end

  def enforce_lead_time?(starts_at)
    starts_at.future?
  end

  def date_range(days_ahead)
    from.to_date..(from.to_date + days_ahead)
  end

  def windows_for(date)
    explicit_windows = overlap_windows(property.availability_windows.bookable_windows, date)
    return explicit_windows if explicit_windows.any?

    return [] unless configuration.open_on?(date)

    [configuration.hours_for(date)]
  end

  def overlap_windows(scope, date)
    day_start = date.beginning_of_day
    day_end = date.end_of_day

    scope
      .select { |window| window.starts_at <= day_end && window.ends_at >= day_start }
      .map do |window|
        [[window.starts_at, day_start].max, [window.ends_at, day_end].min]
      end
      .select { |start_at, end_at| start_at < end_at }
  end

  def within_open_window?(starts_at, ends_at)
    windows_for(starts_at.to_date).any? do |window_start, window_end|
      starts_at >= window_start && ends_at <= window_end
    end
  end

  def blackout_overlap?(starts_at, ends_at)
    overlap_windows(property.availability_windows.blackouts, starts_at.to_date).any? do |blackout_start, blackout_end|
      starts_at < blackout_end && ends_at > blackout_start
    end
  end

  def blocking_overlap?(starts_at, ends_at, excluding_appointment:)
    buffered_start = starts_at - configuration.buffer_minutes.minutes
    buffered_end = ends_at + configuration.buffer_minutes.minutes
    capacity = booking_capacity_for(starts_at, ends_at)

    overlaps = property
      .appointments
      .blocking
      .where.not(id: excluding_appointment&.id)
      .where(scheduled_at: (starts_at - 1.day)..(ends_at + 1.day))
      .count do |appointment|
        existing_start = appointment.scheduled_at - configuration.buffer_minutes.minutes
        existing_end = appointment.end_at + configuration.buffer_minutes.minutes

        buffered_start < existing_end && buffered_end > existing_start
      end

    overlaps >= capacity
  end

  def booking_capacity_for(starts_at, ends_at)
    matching_window = property.availability_windows.bookable_windows.find do |window|
      starts_at >= window.starts_at && ends_at <= window.ends_at
    end

    matching_window&.capacity || 1
  end

  def group_viewing_window?(starts_at, ends_at)
    property.availability_windows.group_viewings.any? do |window|
      starts_at >= window.starts_at && ends_at <= window.ends_at
    end
  end
end
