class Admin < ApplicationRecord
  has_many :assigned_appointments, class_name: 'Appointment', dependent: :nullify
  has_many :assigned_enquiries, class_name: 'Enquiry', dependent: :nullify
  has_many :audit_logs, dependent: :nullify

  devise :two_factor_authenticatable, :two_factor_backupable, :timeoutable

  validates :language, inclusion: { in: AppSettings.available_languages }

  def display_name
    email
  end

  def self.two_factor_globally_active?
    BookingConfiguration.current.admin_two_factor_optional?
  end

  def otp_required_for_login
    two_factor_required_for_sign_in?
  end

  def otp_required_for_login?
    otp_required_for_login
  end

  def two_factor_enrolled?
    stored_otp_required_for_login? && otp_secret.present?
  end

  def two_factor_globally_active?
    self.class.two_factor_globally_active?
  end

  def two_factor_required_for_sign_in?
    two_factor_globally_active? && two_factor_enrolled?
  end

  def two_factor_backup_codes_generated?
    otp_backup_codes.present?
  end

  def stored_otp_required_for_login?
    ActiveModel::Type::Boolean.new.cast(self[:otp_required_for_login])
  end
end
