class Appointment < ApplicationRecord
  STATUSES = %w[pending confirmed rescheduled cancelled completed no_show].freeze
  ACTIVE_STATUSES = %w[pending confirmed rescheduled].freeze
  VISIT_OUTCOMES = %w[attended feedback_requested feedback_received].freeze
  CUSTOMER_SELF_SERVICE_STATUSES = %w[pending confirmed rescheduled].freeze
  PHONE_FORMAT = /\A\+?[0-9().\-\s]{7,20}\z/.freeze
  attr_accessor :skip_slot_validation

  belongs_to :property
  belongs_to :admin, optional: true

  has_many :appointment_events, dependent: :destroy
  has_many :notification_logs, dependent: :destroy

  before_validation :apply_defaults
  before_validation :synchronize_requested_and_scheduled_times

  validates :customer_name, :customer_email, :customer_phone, :requested_time, :scheduled_at, :duration_minutes, :status, :public_reference, :access_token, presence: true
  validates :customer_name, length: { maximum: 100 }
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :customer_phone, format: { with: PHONE_FORMAT, message: ->(_record, _data) { I18n.t("ui.validation.phone_number") } }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }
  validates :visit_outcome, inclusion: { in: VISIT_OUTCOMES }, allow_blank: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than_or_equal_to: 15, less_than_or_equal_to: 240 }, allow_blank: true
  validates :notes, :internal_notes, length: { maximum: 2000 }, allow_blank: true
  validate :slot_available_for_active_bookings, if: :needs_slot_validation?
  validate :past_only_statuses_require_elapsed_slot

  scope :chronological, -> { order(:scheduled_at, :created_at) }
  scope :recent_first, -> { order(scheduled_at: :desc, created_at: :desc) }
  scope :upcoming, -> { where("scheduled_at >= ?", Time.current).chronological }
  scope :pending_action, -> { where(status: %w[pending rescheduled]).chronological }
  scope :blocking, -> { where(status: %w[confirmed rescheduled]) }

  after_create_commit :record_creation_event
  after_create_commit :send_creation_notification
  after_update_commit :record_change_event, if: :noteworthy_change?
  after_update_commit :send_status_notification, if: :notification_worthy_change?

  def to_param
    public_reference
  end

  def end_at
    scheduled_at + duration_minutes.minutes
  end

  def display_status
    I18n.t("ui.appointments.statuses.#{status}", default: status.tr("_", " ").humanize)
  end

  def timeline
    appointment_events.order(:occurred_at, :created_at)
  end

  def manageable_by_customer?
    status.in?(CUSTOMER_SELF_SERVICE_STATUSES) && !self_service_expired?
  end

  def self_service_expires_at
    scheduled_at + 12.hours
  end

  def self_service_expired?
    Time.current > self_service_expires_at
  end

  def valid_access_token?(token)
    token.present? &&
      token.bytesize == access_token.to_s.bytesize &&
      ActiveSupport::SecurityUtils.secure_compare(token, access_token.to_s)
  end

  def customer_history
    self.class.where("lower(customer_email) = ?", customer_email.downcase).where.not(id: id).recent_first
  end

  private

  def apply_defaults
    configuration = BookingConfiguration.current
    self.duration_minutes ||= configuration.slot_duration_minutes
    self.status ||= "pending"
    self.public_reference ||= generate_reference
    self.access_token ||= SecureRandom.hex(16)
  end

  def synchronize_requested_and_scheduled_times
    self.requested_time ||= scheduled_at
    self.scheduled_at ||= requested_time
  end

  def generate_reference
    loop do
      reference = "GTK-#{SecureRandom.alphanumeric(8).upcase}"
      break reference unless self.class.exists?(public_reference: reference)
    end
  end

  def needs_slot_validation?
    !skip_slot_validation && property.present? && scheduled_at.present? && duration_minutes.present? && status.in?(ACTIVE_STATUSES)
  end

  def slot_available_for_active_bookings
    availability = AppointmentAvailability.new(property: property)
    return if availability.slot_available?(scheduled_at, duration_minutes:, excluding_appointment: self)

    errors.add(:scheduled_at, I18n.t("ui.appointments.validation.slot_unavailable"))
  end

  def past_only_statuses_require_elapsed_slot
    return unless status.in?(%w[completed no_show])
    return if scheduled_at.blank? || scheduled_at <= Time.current

    errors.add(:status, I18n.t("ui.appointments.validation.past_only_status", default: "can only be marked once the appointment time has passed"))
  end

  def noteworthy_change?
    previous_changes.key?("status") || previous_changes.key?("scheduled_at") || previous_changes.key?("internal_notes") || previous_changes.key?("notes") || previous_changes.key?("visit_outcome")
  end

  def notification_worthy_change?
    previous_changes.key?("status") || previous_changes.key?("scheduled_at")
  end

  def record_creation_event
    appointment_events.create!(
      event_type: "created",
      to_status: status,
      message: I18n.t(
        "ui.appointments.event_messages.created",
        address: property.address_line_1,
        time: I18n.l(scheduled_at, format: :long)
      ),
      occurred_at: created_at
    )
  end

  def send_creation_notification
    AppointmentNotificationJob.perform_later(id, "created")
  end

  def record_change_event
    if previous_changes.key?("status")
      from_status, to_status = previous_changes.fetch("status")

      appointment_events.create!(
        admin:,
        event_type: to_status,
        from_status:,
        to_status:,
        message: I18n.t(
          "ui.appointments.event_messages.status_changed",
          from_status: I18n.t("ui.appointments.statuses.#{from_status}", default: from_status.humanize.downcase),
          to_status: display_status.downcase
        ),
        occurred_at: updated_at
      )
    elsif previous_changes.key?("scheduled_at")
      from_time, to_time = previous_changes.fetch("scheduled_at")

      appointment_events.create!(
        admin:,
        event_type: "rescheduled",
        from_status: status,
        to_status: status,
        message: I18n.t(
          "ui.appointments.event_messages.moved",
          from_time: I18n.l(from_time, format: :long),
          to_time: I18n.l(to_time, format: :long)
        ),
        occurred_at: updated_at
      )
    elsif previous_changes.key?("internal_notes")
      appointment_events.create!(
        admin:,
        event_type: "internal_note_added",
        from_status: status,
        to_status: status,
        message: I18n.t("ui.appointments.event_messages.internal_notes_updated"),
        occurred_at: updated_at
      )
    elsif previous_changes.key?("notes")
      appointment_events.create!(
        admin:,
        event_type: "customer_note_updated",
        from_status: status,
        to_status: status,
        message: I18n.t("ui.appointments.event_messages.customer_notes_updated"),
        occurred_at: updated_at
      )
    elsif previous_changes.key?("visit_outcome")
      _from_outcome, to_outcome = previous_changes.fetch("visit_outcome")

      appointment_events.create!(
        admin:,
        event_type: to_outcome,
        from_status: status,
        to_status: status,
        message: I18n.t(
          "ui.appointments.event_messages.visit_outcome_marked",
          outcome: I18n.t("ui.appointments.visit_outcomes.#{to_outcome}", default: to_outcome.to_s.tr("_", " ").downcase)
        ),
        occurred_at: updated_at
      )
    end
  end

  def send_status_notification
    event_type =
      if previous_changes.key?("status")
        status
      else
        "rescheduled"
      end

    AppointmentNotificationJob.perform_later(id, event_type)
  end
end
