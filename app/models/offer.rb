class Offer < ApplicationRecord
  STATUSES = %w[received accepted rejected withdrawn completed].freeze
  PHONE_FORMAT = /\A\+?[0-9().\-\s]{7,20}\z/.freeze

  belongs_to :property
  belongs_to :admin, optional: true

  has_many :offer_events, dependent: :destroy
  has_many :audit_logs, as: :auditable, dependent: :destroy

  before_validation :apply_defaults

  validates :public_reference, :buyer_name, :buyer_email, :buyer_phone, :amount, :status, presence: true
  validates :buyer_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :buyer_phone, format: { with: PHONE_FORMAT, message: "must be a valid phone number" }
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :buyer_name, length: { maximum: 100 }
  validates :chain_position, length: { maximum: 120 }, allow_blank: true
  validates :notes, :internal_notes, length: { maximum: 3000 }, allow_blank: true
  validate :sale_listing_only

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  after_create_commit :record_creation_event
  after_create_commit :record_creation_audit_log
  after_update_commit :record_status_event, if: -> { previous_changes.key?("status") }
  after_save_commit :sync_property_progression, if: -> { previous_changes.key?("status") }

  def timeline
    offer_events.chronological
  end

  private

  def apply_defaults
    self.status ||= "received"
    self.public_reference ||= generate_reference
  end

  def generate_reference
    loop do
      reference = "OFF-#{SecureRandom.alphanumeric(7).upcase}"
      break reference unless self.class.exists?(public_reference: reference)
    end
  end

  def sale_listing_only
    return if property.blank? || property.sale_status == Property::SALE_STATUSES[:for_sale]

    errors.add(:property, "must be a sale listing")
  end

  def record_creation_event
    offer_events.create!(
      admin:,
      event_type: "received",
      to_status: status,
      message: "Offer received at #{ApplicationController.helpers.number_to_currency(amount, unit: '£', precision: 0)}.",
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
      message: "Offer status changed from #{from_status.to_s.humanize.downcase} to #{to_status.to_s.humanize.downcase}.",
      occurred_at: updated_at
    )
  end

  def sync_property_progression
    case status
    when "accepted"
      property.update!(listing_state: "under_offer")
    when "completed"
      property.update!(listing_state: "sold")
    when "rejected", "withdrawn"
      property.update!(listing_state: "published") if property.listing_state == "under_offer" && property.offers.where(status: "accepted").where.not(id: id).none?
    end
  end

  def record_creation_audit_log
    AuditLogger.log!(
      auditable: self,
      property: property,
      actor_label: buyer_email,
      action: "offer_created",
      message: "Offer received from #{buyer_name} at #{ApplicationController.helpers.number_to_currency(amount, unit: '£', precision: 0)}."
    )
  end
end
