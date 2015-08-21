class Admin < ActiveRecord::Base

  devise :database_authenticatable, :timeoutable

  # TODO validate these symbols in LANGUAGES
  validates :language, inclusion: {in: LANGUAGES}

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :language

end
