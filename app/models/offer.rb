class Offer < ApplicationRecord
  include PhoneNumberNormalizable

  STATUSES = %w[received accepted rejected withdrawn completed].freeze
  PHONE_FORMAT = /\A\+?[0-9().\-\s]{7,20}\z/.freeze

  belongs_to :property
  belongs_to :admin, optional: true

  has_many :offer_events, dependent: :destroy
  has_many :audit_logs, as: :auditable, dependent: :destroy

  def amount=(value)
    super(normalize_integer_input(value))
  end

  before_validation :apply_defaults
  normalizes_phone_number :buyer_phone

  validates :public_reference, :buyer_name, :buyer_email, :buyer_phone, :amount, :status, presence: true
  validates :buyer_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :buyer_phone, format: { with: PHONE_FORMAT, message: ->(_record, _data) { I18n.t("ui.validation.phone_number") } }
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :buyer_name, length: { maximum: 100 }
  validates :chain_position, length: { maximum: 120 }, allow_blank: true
  validates :notes, :internal_notes, length: { maximum: 3000 }, allow_blank: true
  validate :sale_listing_only
  validate :buyer_cannot_be_property_owner

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  after_create_commit :record_creation_event
  after_create_commit :record_creation_audit_log
  after_update_commit :record_status_event, if: -> { previous_changes.key?("status") }
  after_save_commit :sync_property_progression, if: -> { previous_changes.key?("status") }

  def timeline
    offer_events.chronological
  end

  def withdrawable?
    status.in?(%w[received accepted])
  end

  private

  def normalize_integer_input(value)
    value.to_s.gsub(/[,\s]/, "").presence
  end

  def apply_defaults
    self.status ||= "received"
    self.public_reference ||= generate_reference
  end

  def generate_reference
    loop do
      reference = "GTK-OFR-#{SecureRandom.alphanumeric(8).upcase}"
      break reference unless self.class.exists?(public_reference: reference)
    end
  end

  def sale_listing_only
    return if property.blank? || property.sale_status == Property::SALE_STATUSES[:for_sale]

    errors.add(:property, I18n.t("ui.offers.validation.sale_listing_only"))
  end

  def buyer_cannot_be_property_owner
    return if property.blank? || buyer_email.blank? || property.user&.email.blank?
    return unless buyer_email.strip.casecmp?(property.user.email.strip)

    errors.add(:buyer_email, I18n.t("ui.offers.validation.owner_cannot_offer"))
  end

  def record_creation_event
    offer_events.create!(
      admin:,
      event_type: "received",
      to_status: status,
      message: I18n.t(
        "ui.offers.events.received",
        amount: ApplicationController.helpers.number_to_currency(amount, unit: "£", precision: 0)
      ),
      occurred_at: created_at
    )
  end

  def record_status_event
    from_status, to_status = previous_changes.fetch("status")
    offer_events.create!(
      admin:,
      event_type: to_status,
      from_status: from_status,
      to_status: to_status,
      message: I18n.t(
        "ui.offers.events.status_changed",
        from_status: I18n.t("ui.offers.statuses.#{from_status}", default: from_status.to_s.humanize.downcase),
        to_status: I18n.t("ui.offers.statuses.#{to_status}", default: to_status.to_s.humanize.downcase)
      ),
      occurred_at: updated_at
    )
  end

  def sync_property_progression
    property.with_lock do
      case status
      when "accepted"
        property.update!(listing_state: "under_offer")
      when "completed"
        property.update!(listing_state: "sold")
      when "rejected", "withdrawn"
        property.update!(listing_state: "published") if property.listing_state == "under_offer" && property.offers.where(status: "accepted").where.not(id: id).none?
      end
    end
  end

  def record_creation_audit_log
    AuditLogger.log!(
      auditable: self,
      property: property,
      actor_label: buyer_email,
      action: "offer_created",
      message: I18n.t(
        "ui.offers.audit.created",
        name: buyer_name,
        amount: ApplicationController.helpers.number_to_currency(amount, unit: "£", precision: 0)
      )
    )
  end
end
