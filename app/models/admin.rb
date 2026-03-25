class Admin < ApplicationRecord

  devise :database_authenticatable, :timeoutable

  validates :language, inclusion: { in: AppSettings.available_languages }
end
