class Admin < ApplicationRecord
  has_many :assigned_appointments, class_name: 'Appointment', dependent: :nullify

  devise :database_authenticatable, :timeoutable

  validates :language, inclusion: { in: AppSettings.available_languages }

  def display_name
    email
  end
end
