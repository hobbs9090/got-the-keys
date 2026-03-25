class AvailabilityWindow < ApplicationRecord
  KINDS = %w[open blackout].freeze

  belongs_to :property

  validates :starts_at, :ends_at, :kind, presence: true
  validates :kind, inclusion: { in: KINDS }
  validate :starts_before_ends

  scope :open_windows, -> { where(kind: "open").order(:starts_at) }
  scope :blackouts, -> { where(kind: "blackout").order(:starts_at) }

  def open?
    kind == "open"
  end

  def blackout?
    kind == "blackout"
  end

  private

  def starts_before_ends
    return if starts_at.blank? || ends_at.blank?
    return if starts_at < ends_at

    errors.add(:ends_at, "must be after the start time")
  end
end
