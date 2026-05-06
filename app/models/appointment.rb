class Appointment < ApplicationRecord
  STATUSES = %w[pending confirmed rescheduled cancelled completed no_show].freeze
  ACTIVE_STATUSES = %w[pending confirmed rescheduled].freeze
  VISIT_OUTCOMES = %w[attended feedback_requested feedback_received].freeze
  CUSTOMER_SELF_SERVICE_STATUSES = %w[pending confirmed rescheduled].freeze
  # Customers can manage a viewing until two hours before it starts. The
  # deadline is relative to the actual scheduled start, not the calendar day,
  # so same-day and DST-crossing bookings do not stay editable after the cutoff.
  CUSTOMER_SELF_SERVICE_CUTOFF = 2.hours
  ACCESS_TOKEN_BYTES = 32
  ACCESS_TOKEN_TTL = 30.days
  PHONE_FORMAT = /\A\+?[0-9().\-\s]{7,20}\z/.freeze
  attr_accessor :skip_slot_validation

  # Admin customer directory rows are loaded through Appointment-backed SQL
  # projections, so these aliases need explicit datetime casting.
  attribute :latest_appointment_at, :datetime
  attribute :registered_at, :datetime
  attribute :sort_at, :datetime

  belongs_to :property
  belongs_to :admin, optional: true

  has_many :appointment_events, dependent: :destroy
  has_many :notification_logs, dependent: :destroy

  before_validation :apply_defaults
  before_validation :synchronize_requested_and_scheduled_times

  validates :customer_name, :customer_email, :customer_phone, :requested_time, :scheduled_at, :duration_minutes, :status, :public_reference,
            :access_token_digest, :access_token_expires_at, presence: true
  validates :customer_name, length: { maximum: 100 }
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :customer_phone, format: { with: PHONE_FORMAT, message: ->(_record, _data) { I18n.t("ui.validation.phone_number") } }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }
  validates :visit_outcome, inclusion: { in: VISIT_OUTCOMES }, allow_blank: true
  validates :duration_minutes, numericality: { only_integer: true }, allow_blank: true
  validates :duration_minutes, inclusion: { in: BookingConfiguration::SUPPORTED_SLOT_DURATIONS }, allow_blank: true
  validates :notes, :internal_notes, length: { maximum: 2000 }, allow_blank: true
  validate :slot_available_for_active_bookings, if: :needs_slot_validation?
  validate :past_only_statuses_require_elapsed_slot
  validate :completed_appointments_cannot_return_to_confirmed

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

  def matched_user
    return @matched_user if defined?(@matched_user)

    @matched_user =
      User
        .where(
          "lower(email) = :email OR (mobile_number = :phone AND lower(trim(coalesce(first_name, '') || ' ' || coalesce(last_name, ''))) = :name)",
          email: customer_email.to_s.downcase,
          phone: customer_phone.to_s,
          name: customer_name.to_s.downcase
        )
        .first
  end

  def display_customer_email
    matched_user&.email.presence || customer_email
  end

  def timeline
    appointment_events.order(:occurred_at, :created_at)
  end

  def confirmable_by_admin?
    return false if status.in?(%w[confirmed completed no_show])
    return false if scheduled_at.present? && end_at < Time.current

    true
  end

  def manageable_by_customer?
    status.in?(CUSTOMER_SELF_SERVICE_STATUSES) && !self_service_expired?
  end

  def self_service_expires_at
    scheduled_at - CUSTOMER_SELF_SERVICE_CUTOFF
  end

  def self_service_expired?
    Time.current > self_service_expires_at
  end

  def valid_access_token?(token)
    return false if token.blank? || access_token_expired?

    digest = self.class.access_token_digest_for(token)
    ActiveSupport::SecurityUtils.secure_compare(digest, access_token_digest.to_s)
  end

  def access_token
    @access_token
  end

  def issue_access_token!(expires_at: self.class.default_access_token_expires_at)
    assign_new_access_token(expires_at:)
    save!(validate: false)
    access_token
  end

  def access_token_expired?
    access_token_expires_at.blank? || Time.current > access_token_expires_at
  end

  def self.access_token_digest_for(token)
    Digest::SHA256.hexdigest(token.to_s)
  end

  def self.default_access_token_expires_at
    Time.current + ACCESS_TOKEN_TTL
  end

  def customer_history
    scope = self.class.where.not(id: id)

    if matched_user.present?
      scope.where(
        "lower(customer_email) = :email OR (customer_phone = :phone AND lower(customer_name) = :name)",
        email: matched_user.email.downcase,
        phone: matched_user.mobile_number,
        name: matched_user.full_name.downcase
      ).recent_first
    else
      scope.where("lower(customer_email) = ?", customer_email.downcase).recent_first
    end
  end

  private

  def apply_defaults
    configuration = BookingConfiguration.current
    self.duration_minutes ||= configuration.slot_duration_minutes
    self.status ||= "pending"
    self.public_reference ||= generate_reference
    assign_new_access_token if access_token_digest.blank?
  end

  def assign_new_access_token(expires_at: self.class.default_access_token_expires_at)
    self.access_token_expires_at = expires_at

    loop do
      @access_token = SecureRandom.urlsafe_base64(ACCESS_TOKEN_BYTES)
      self.access_token_digest = self.class.access_token_digest_for(@access_token)
      break unless self.class.exists?(access_token_digest:)
    end
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

  def completed_appointments_cannot_return_to_confirmed
    return unless persisted?
    return unless will_save_change_to_status?
    return unless status_in_database == "completed" && status == "confirmed"

    errors.add(:status, I18n.t("ui.appointments.validation.completed_cannot_be_confirmed", default: "cannot be changed back to confirmed once completed"))
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
    AppointmentNotificationJob.perform_later(id, "created", access_token)
  end

  def record_change_event
    AppointmentEventRecorder.new(self).record_change_events
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
