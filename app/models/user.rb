class User < ActiveRecord::Base

  has_many :properties, dependent: :destroy

  after_initialize :init

  validates :first_name, :last_name, :mobile_number, presence: true

  validates :terms_of_service, acceptance: true

  validates :first_name, :last_name, length: {maximum: 50}

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  # TODO add the :confirmable module back in for prod
  devise :database_authenticatable, :lockable, :registerable, #:confirmable,
         :recoverable, :rememberable, :timeoutable, :trackable, :validatable

  validates :language, inclusion: {in: LANGUAGES}

  # Setup accessible (or protected) attributes for your model
  attr_accessible :first_name, :last_name, :mobile_number, :email, :password, :password_confirmation, :remember_me, :language, :properties_count, :terms_of_service

  def init
    self.language ||= I18n.default_locale # will set the default value only if it's nil
  end

  def self.user_count
    count
  end

  def self.total_number_en_users
    where(:language => 'en').count
  end

  def self.total_number_zh_users
    where(:language => 'zh').count
  end

  def self.active_today
    where("DATE(last_sign_in_at) = DATE(?)", Time.now).count
  end

  def self.added_today
    where("DATE(created_at) = DATE(?)", Time.now).count
  end

end
