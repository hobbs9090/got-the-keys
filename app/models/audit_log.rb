class AuditLog < ApplicationRecord
  belongs_to :property, optional: true
  belongs_to :admin, optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, :message, :occurred_at, presence: true

  scope :recent_first, -> { order(occurred_at: :desc, created_at: :desc) }

  def actor_display
    admin&.email.presence || actor_label.presence || "System"
  end
end
