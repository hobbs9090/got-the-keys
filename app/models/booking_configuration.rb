class BookingConfiguration < ApplicationRecord
  ADMIN_TWO_FACTOR_MODES = %w[disabled optional].freeze
  DEFAULT_OPEN_WEEKDAYS = %w[1 2 3 4 5 6].freeze
  SUPPORTED_SLOT_DURATIONS = [30, 45, 60].freeze
  CLOCK_FORMAT = /\A\d{2}:\d{2}\z/

  validates :slot_duration_minutes, :booking_window_days, :lead_time_hours, :buffer_minutes, :office_opens_at, :office_closes_at, presence: true
  validates :admin_two_factor_mode, inclusion: { in: ADMIN_TWO_FACTOR_MODES }
  validates :slot_duration_minutes, numericality: { only_integer: true }, allow_blank: true
  validates :slot_duration_minutes, inclusion: { in: SUPPORTED_SLOT_DURATIONS }, allow_blank: true
  validates :booking_window_days, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 60 }, allow_blank: true
  validates :lead_time_hours, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 336 }, allow_blank: true
  validates :buffer_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 180 }, allow_blank: true
  validates :office_opens_at, :office_closes_at, format: {
    with: CLOCK_FORMAT,
    message: ->(_record, _data) { I18n.t("ui.admin.booking_configuration.validation.clock_format", default: "must use 24-hour HH:MM format") }
  }, allow_blank: true
  validate :office_hours_in_order
  validate :open_weekdays_present

  class << self
    def current
      first_or_create!(default_attributes)
    end

    private

    def default_attributes
      {
        slot_duration_minutes: 45,
        booking_window_days: 21,
        lead_time_hours: 4,
        buffer_minutes: 15,
        office_opens_at: "09:00",
        office_closes_at: "18:00",
        open_weekdays: DEFAULT_OPEN_WEEKDAYS.join(","),
        active_demo_scenario_key: "baseline",
        admin_two_factor_mode: "disabled"
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

    super(normalized)
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

  def admin_two_factor_disabled?
    admin_two_factor_mode == "disabled"
  end

  def admin_two_factor_optional?
    admin_two_factor_mode == "optional"
  end

  private

  def office_hours_in_order
    return if office_opens_at.blank? || office_closes_at.blank?
    return if parse_clock(Date.current, office_opens_at) < parse_clock(Date.current, office_closes_at)

    errors.add(:office_closes_at, I18n.t("ui.admin.booking_configuration.validation.closes_after_open", default: "must be later than the opening time"))
  end

  def open_weekdays_present
    return if open_weekday_numbers.any?

    errors.add(:open_weekdays, I18n.t("ui.admin.booking_configuration.validation.open_weekdays_present", default: "must include at least one day"))
  end

  def parse_clock(date, value)
    hour, minute = value.split(":").map(&:to_i)
    Time.zone.local(date.year, date.month, date.day, hour, minute)
  end
end
