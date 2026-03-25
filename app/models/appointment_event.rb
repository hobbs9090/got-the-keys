class AppointmentEvent < ApplicationRecord
  belongs_to :appointment
  belongs_to :admin, optional: true

  validates :event_type, :occurred_at, presence: true

  before_validation :set_occurred_at

  scope :chronological, -> { order(:occurred_at, :created_at) }

  private

  def set_occurred_at
    self.occurred_at ||= Time.current
  end
end
