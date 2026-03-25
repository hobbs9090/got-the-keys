class BookingConfiguration < ApplicationRecord
  DEFAULT_OPEN_WEEKDAYS = %w[1 2 3 4 5 6].freeze
  CLOCK_FORMAT = /\A\d{2}:\d{2}\z/

  validates :slot_duration_minutes, numericality: { greater_than_or_equal_to: 15, less_than_or_equal_to: 240 }
  validates :lead_time_hours, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 336 }
  validates :buffer_minutes, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 180 }
  validates :office_opens_at, :office_closes_at, format: { with: CLOCK_FORMAT }
  validate :office_hours_in_order

  class << self
    def current
      first_or_create!(default_attributes)
    end

    private

    def default_attributes
      {
        slot_duration_minutes: 45,
        lead_time_hours: 4,
        buffer_minutes: 15,
        office_opens_at: "09:00",
        office_closes_at: "18:00",
        open_weekdays: DEFAULT_OPEN_WEEKDAYS.join(","),
        active_demo_scenario_key: "baseline"
      }
    end
  end

  def open_weekdays=(value)
    normalized =
      Array(value)
        .flat_map { |entry| entry.to_s.split(",") }
        .reject(&:blank?)
        .map(&:to_i)
        .uniq
        .sort
        .join(",")

    super(normalized.presence || DEFAULT_OPEN_WEEKDAYS.join(","))
  end

  def open_weekday_numbers
    open_weekdays.to_s.split(",").map(&:to_i)
  end

  def open_on?(date)
    open_weekday_numbers.include?(date.wday)
  end

  def hours_for(date)
    [parse_clock(date, office_opens_at), parse_clock(date, office_closes_at)]
  end

  private

  def office_hours_in_order
    return if office_opens_at.blank? || office_closes_at.blank?
    return if parse_clock(Date.current, office_opens_at) < parse_clock(Date.current, office_closes_at)

    errors.add(:office_closes_at, "must be later than the opening time")
  end

  def parse_clock(date, value)
    hour, minute = value.split(":").map(&:to_i)
    Time.zone.local(date.year, date.month, date.day, hour, minute)
  end
end
