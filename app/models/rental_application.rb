class RentalApplication < ApplicationRecord
  STATUSES = %w[received referencing approved rejected withdrawn].freeze
  PHONE_FORMAT = /\A\+?[0-9().\-\s]{7,20}\z/.freeze

  belongs_to :property
  belongs_to :admin, optional: true

  has_many :rental_application_events, dependent: :destroy
  has_many :audit_logs, as: :auditable, dependent: :destroy

  before_validation :apply_defaults

  validates :public_reference, :applicant_name, :applicant_email, :applicant_phone, :move_in_date, :status, presence: true
  validates :applicant_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :applicant_phone, format: { with: PHONE_FORMAT, message: ->(_record, _data) { I18n.t("ui.validation.phone_number") } }
  validates :status, inclusion: { in: STATUSES }
  validates :applicant_name, length: { maximum: 100 }
  validates :affordability_notes, :notes, :internal_notes, length: { maximum: 3000 }, allow_blank: true
  validate :rental_listing_only

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  after_create_commit :record_creation_event
  after_create_commit :record_creation_audit_log
  after_update_commit :record_status_event, if: -> { previous_changes.key?("status") }
  after_save_commit :sync_property_progression, if: -> { previous_changes.key?("status") }

  def timeline
    rental_application_events.chronological
  end

  def withdrawable?
    status.in?(%w[received referencing])
  end

  private

  def apply_defaults
    self.status ||= "received"
    self.public_reference ||= generate_reference
  end

  def generate_reference
    loop do
      reference = "LET-#{SecureRandom.alphanumeric(7).upcase}"
      break reference unless self.class.exists?(public_reference: reference)
    end
  end

  def rental_listing_only
    return if property.blank? || property.sale_status == Property::SALE_STATUSES[:for_rent]

    errors.add(:property, I18n.t("ui.rental_applications.validation.rental_listing_only"))
  end

  def record_creation_event
    rental_application_events.create!(
      admin:,
      event_type: "received",
      to_status: status,
      message: I18n.t("ui.rental_applications.events.received", move_in_date: I18n.l(move_in_date, format: :long)),
      occurred_at: created_at
    )
  end

  def record_status_event
    from_status, to_status = previous_changes.fetch("status")
    rental_application_events.create!(
      admin:,
      event_type: to_status,
      from_status: from_status,
      to_status: to_status,
      message: I18n.t(
        "ui.rental_applications.events.status_changed",
        from_status: I18n.t("ui.rental_applications.statuses.#{from_status}", default: from_status.to_s.humanize.downcase),
        to_status: I18n.t("ui.rental_applications.statuses.#{to_status}", default: to_status.to_s.humanize.downcase)
      ),
      occurred_at: updated_at
    )
  end

  def sync_property_progression
    property.with_lock do
      case status
      when "approved"
        property.update!(listing_state: "let_agreed")
      when "rejected", "withdrawn"
        property.update!(listing_state: "published") if property.listing_state == "let_agreed" && property.rental_applications.where(status: "approved").where.not(id: id).none?
      end
    end
  end

  def record_creation_audit_log
    AuditLogger.log!(
      auditable: self,
      property: property,
      actor_label: applicant_email,
      action: "rental_application_created",
      message: I18n.t(
        "ui.rental_applications.audit.created",
        name: applicant_name,
        move_in_date: I18n.l(move_in_date, format: :long)
      )
    )
  end
end
