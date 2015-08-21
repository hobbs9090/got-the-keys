class ViewingTime < ActiveRecord::Base

  belongs_to :property

  validates :start_time, :end_time, presence: true

  # TODO fix this validation
  #validates :start_time < :end_time, inclusion: {
  #    message: "start time must be before end time"
  #}

  attr_accessible :start_time, :end_time

end
