class FloorPlan < ActiveRecord::Base

  belongs_to :property

  attr_accessible :floor_plans

end
