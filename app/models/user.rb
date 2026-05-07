class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  PHONE_FORMAT = /\A\+?[0-9().\-\s]{7,20}\z/.freeze

  has_many :properties, dependent: :destroy
  has_many :saved_properties, dependent: :destroy
  has_many :saved_listings, through: :saved_properties, source: :property
  has_many :saved_searches, dependent: :destroy
  has_many :api_refresh_tokens, dependent: :destroy

  after_initialize :set_defaults, if: :new_record?
  before_validation :strip_form_fields
  before_create :set_initial_jti
  after_update_commit :sync_associated_email_records, if: :saved_change_to_email?

  validates :first_name, :last_name, presence: true
  validates :mobile_number, presence: true, unless: :admin_provisioned?
  validates :terms_of_service, acceptance: true
  validates :first_name, :last_name, length: { maximum: 50 }
  validates :mobile_number, format: { with: PHONE_FORMAT, message: ->(_record, _data) { I18n.t("ui.validation.phone_number") } }, allow_blank: true
  validates :language, presence: true
  validates :language, inclusion: { in: AppSettings.available_languages }, allow_blank: true
  validate :password_includes_letters_and_numbers, if: -> { password.present? }

  devise :database_authenticatable, :lockable, :registerable,
         :recoverable, :rememberable, :timeoutable, :trackable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  class << self
    def user_count
      count
    end

    def total_number_en_users
      where(language: 'en').count
    end

    def total_number_zh_users
      where(language: 'zh').count
    end

    def active_today
      where(last_sign_in_at: Time.current.all_day).count
    end

    def added_today
      where(created_at: Time.current.all_day).count
    end
  end

  # JWT payload customization. Adds aud/iat in addition to the default sub/jti/exp.
  def jwt_payload
    {
      "aud" => "ios",
      "iat" => Time.current.to_i
    }
  end

  # Rotate the JTI, invalidating every outstanding access token issued for this
  # user. Used by Api::V1::Auth::SessionsController#destroy.
  def rotate_jwt_jti!
    update_columns(jti: SecureRandom.uuid, updated_at: Time.current)
  end

  private

  def set_defaults
    self.language ||= I18n.default_locale.to_s
  end

  def set_initial_jti
    self.jti ||= SecureRandom.uuid
  end

  def strip_form_fields
    self.first_name = first_name.to_s.strip
    self.last_name = last_name.to_s.strip
    self.mobile_number = mobile_number&.strip
    self.email = email.to_s.strip
    self.language = language.to_s.strip
  end

  def password_includes_letters_and_numbers
    return if password.match?(/[A-Za-z]/) && password.match?(/\d/)

    errors.add(:password, :letter_number)
  end

  public

  def send_reset_password_instructions
    return if admin_provisioned?
    super
  end

  def full_name
    [first_name, last_name].reject(&:blank?).join(' ')
  end

  private

  def sync_associated_email_records
    old_email, new_email = saved_change_to_email
    return if old_email.blank? || new_email.blank?

    now = Time.current
    ApplicationRecord.transaction do
      Appointment.where("lower(customer_email) = ?", old_email.downcase).update_all(customer_email: new_email, updated_at: now)
      Offer.where("lower(buyer_email) = ?", old_email.downcase).update_all(buyer_email: new_email, updated_at: now)
      RentalApplication.where("lower(applicant_email) = ?", old_email.downcase).update_all(applicant_email: new_email, updated_at: now)
      Enquiry.where("lower(customer_email) = ?", old_email.downcase).update_all(customer_email: new_email, updated_at: now)
      saved_searches.update_all(email: new_email, updated_at: now)
    end
  end
end
