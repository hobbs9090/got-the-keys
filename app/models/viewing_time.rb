class ViewingTime < ApplicationRecord
  belongs_to :property

  validates :start_time, :end_time, presence: true
  validate :start_time_before_end_time

  private

  def start_time_before_end_time
    return if start_time.blank? || end_time.blank?
    return if start_time < end_time

    errors.add(:end_time, "must be after the start time")
  end
end
