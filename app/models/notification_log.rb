class NotificationLog < ApplicationRecord
  STATUSES = %w[sent skipped failed].freeze

  belongs_to :appointment, optional: true

  validates :subject, :event_type, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(created_at: :desc) }
end
