class Admin < ActiveRecord::Base

  devise :database_authenticatable, :timeoutable

  # TODO validate these symbols in LANGUAGES
  validates :language, inclusion: {in: LANGUAGES}

  # Strong parameters in controller

end
