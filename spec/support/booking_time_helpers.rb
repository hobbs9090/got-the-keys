module BookingTimeHelpers
  DEFAULT_BOOKING_RULES = {
    slot_duration_minutes: 45,
    booking_window_days: 21,
    lead_time_hours: 4,
    buffer_minutes: 15,
    office_opens_at: "09:00",
    office_closes_at: "17:00",
    open_weekdays: %w[1 2 3 4 5],
    active_demo_scenario_key: "baseline"
  }.freeze

  module_function

  def configure_booking_rules!(**overrides)
    BookingConfiguration.current.update!(DEFAULT_BOOKING_RULES.merge(overrides))
  end

  def next_booking_slot(hour: 10, minutes: 0, from: Time.current, configuration: BookingConfiguration.current)
    date = from.to_date

    loop do
      candidate = booking_time_on(date, hour:, minutes:)
      return candidate if configuration.open_on?(date) && candidate > from + configuration.lead_time_hours.hours

      date += 1.day
    end
  end

  def booking_time(year, month, day, hour, minutes = 0)
    Time.zone.local(year, month, day, hour, minutes)
  end

  def booking_time_on(date, hour:, minutes: 0)
    booking_time(date.year, date.month, date.day, hour, minutes)
  end

  def booking_window(date:, hour:, minutes: 0, duration_minutes: BookingConfiguration.current.slot_duration_minutes)
    starts_at = booking_time_on(date, hour:, minutes:)
    [starts_at, starts_at + duration_minutes.minutes]
  end
end

RSpec.configure do |config|
  config.include BookingTimeHelpers
end
