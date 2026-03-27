class Enquiry < ApplicationRecord
  STATUSES = %w[new contacted qualified unqualified archived].freeze
  SOURCE_TYPES = %w[general_enquiry brochure_request valuation_request letting_enquiry].freeze
  PHONE_FORMAT = /\A\+?[0-9().\-\s]{7,20}\z/.freeze
  SPAM_HINTS = [
    /crypto/i,
    /seo/i,
    /backlinks?/i,
    /whatsapp/i,
    /telegram/i,
    /investment opportunity/i
  ].freeze

  attr_accessor :skip_notifications

  belongs_to :property
  belongs_to :admin, optional: true

  has_many :notification_logs, dependent: :nullify
  has_many :audit_logs, as: :auditable, dependent: :destroy

  before_validation :apply_defaults
  before_validation :flag_suspected_spam

  validates :lead_reference, :status, :source_type, :customer_name, :message, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validates :customer_name, length: { maximum: 100 }
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :customer_phone, format: { with: PHONE_FORMAT, message: ->(_record, _data) { I18n.t("ui.validation.phone_number") } }, allow_blank: true
  validates :message, length: { minimum: 20, maximum: 3000 }
  validates :internal_notes, length: { maximum: 3000 }, allow_blank: true
  validate :email_or_phone_present

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
  scope :for_status, ->(status) { where(status:) if status.present? }
  scope :for_source_type, ->(source_type) { where(source_type:) if source_type.present? }
  scope :assigned_to, ->(admin_id) { where(admin_id:) if admin_id.present? }
  scope :open_pipeline, -> { where(status: %w[new contacted qualified]) }
  scope :flagged_spam, -> { where(spam: true) }

  after_create_commit :enqueue_creation_notifications, unless: :skip_notifications?
  after_create_commit :record_creation_audit_log

  def self.create_seeded!(property:, admin: nil, allow_invalid: false, **attributes)
    enquiry = property.enquiries.new(attributes.merge(admin:))
    enquiry.skip_notifications = true
    enquiry.send(:apply_defaults)
    enquiry.send(:flag_suspected_spam)
    enquiry.save!(validate: !allow_invalid)
    enquiry
  end

  def display_status
    I18n.t("ui.enquiries.statuses.#{status}", default: status.to_s.tr("_", " ").humanize)
  end

  def display_source
    I18n.t("ui.enquiries.source_types.#{source_type}", default: source_type.to_s.tr("_", " ").humanize)
  end

  private

  def apply_defaults
    self.status ||= "new"
    self.source_type ||= "general_enquiry"
    self.lead_reference ||= generate_reference
  end

  def generate_reference
    loop do
      reference = "LEAD-#{SecureRandom.alphanumeric(7).upcase}"
      break reference unless self.class.exists?(lead_reference: reference)
    end
  end

  def email_or_phone_present
    return if customer_email.present? || customer_phone.present?

    errors.add(:base, I18n.t("ui.enquiries.validation.contact_required"))
  end

  def flag_suspected_spam
    return if spam?
    return unless suspicious_message? || suspicious_email?

    self.spam = true
    self.spam_reason ||= "Automatic spam heuristic"
  end

  def suspicious_message?
    body = message.to_s
    return false if body.blank?

    body.scan(%r{https?://}i).size >= 2 || SPAM_HINTS.any? { |pattern| body.match?(pattern) }
  end

  def suspicious_email?
    customer_email.to_s.match?(/\A[a-z0-9._%+-]+@(qq|mailinator|tempmail)\./i)
  end

  def enqueue_creation_notifications
    EnquiryNotificationJob.perform_later(id, "created")
  end

  def skip_notifications?
    ActiveModel::Type::Boolean.new.cast(skip_notifications)
  end

  def record_creation_audit_log
    AuditLogger.log!(
      auditable: self,
      property: property,
      actor_label: customer_email.presence || customer_name,
      action: "enquiry_created",
      message: I18n.t("ui.enquiries.audit.created", source: display_source.downcase, name: customer_name)
    )
  end
end
