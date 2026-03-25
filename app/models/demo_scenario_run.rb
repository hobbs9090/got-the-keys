class DemoScenarioRun < ApplicationRecord
  ACTION_TYPES = %w[apply restore import export].freeze

  validates :action_type, inclusion: { in: ACTION_TYPES }

  scope :recent_first, -> { order(created_at: :desc) }
end
