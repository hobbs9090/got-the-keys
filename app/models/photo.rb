class Photo < ActiveRecord::Base

  belongs_to :property

  attr_accessible :image_filename

end
