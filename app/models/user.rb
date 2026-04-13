class User < ApplicationRecord
  PHONE_FORMAT = /\A\+?[0-9().\-\s]{7,20}\z/.freeze

  has_many :properties, dependent: :destroy
  has_many :saved_properties, dependent: :destroy
  has_many :saved_listings, through: :saved_properties, source: :property
  has_many :saved_searches, dependent: :destroy

  after_initialize :set_defaults, if: :new_record?
  before_validation :strip_form_fields

  validates :first_name, :last_name, :mobile_number, presence: true
  validates :terms_of_service, acceptance: true
  validates :first_name, :last_name, length: { maximum: 50 }
  validates :mobile_number, format: { with: PHONE_FORMAT, message: ->(_record, _data) { I18n.t("ui.validation.phone_number") } }, allow_blank: true
  validates :language, presence: true
  validates :language, inclusion: { in: AppSettings.available_languages }, allow_blank: true

  devise :database_authenticatable, :lockable, :registerable,
         :recoverable, :rememberable, :timeoutable, :trackable, :validatable

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

  private

  def set_defaults
    self.language ||= I18n.default_locale.to_s
  end

  def strip_form_fields
    self.first_name = first_name.to_s.strip
    self.last_name = last_name.to_s.strip
    self.mobile_number = mobile_number.to_s.strip
    self.email = email.to_s.strip
    self.language = language.to_s.strip
  end

  public

  def full_name
    [first_name, last_name].reject(&:blank?).join(' ')
  end
end
