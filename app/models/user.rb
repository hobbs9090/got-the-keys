class User < ApplicationRecord
  has_many :properties, dependent: :destroy

  after_initialize :set_defaults, if: :new_record?

  validates :first_name, :last_name, :mobile_number, presence: true
  validates :terms_of_service, acceptance: true
  validates :first_name, :last_name, length: { maximum: 50 }
  validates :language, inclusion: { in: AppSettings.available_languages }

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
end
