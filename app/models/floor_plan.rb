class FloorPlan < ApplicationRecord
  belongs_to :property

  validates :floor_plans, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
