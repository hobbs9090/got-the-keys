class Property < ActiveRecord::Base

  belongs_to :user, counter_cache: true

  has_many :photos, dependent: :destroy

  has_many :floor_plans, dependent: :destroy

  has_many :viewing_times, dependent: :destroy

  validates :address_line_1, :town_city, :county, :postcode, :country, :property_description, :bedrooms, :sale_status, :asking_price, :user_id, presence: true

  validates :address_line_1, :address_line_2, :town_city, :county, :postcode, :country, length: {maximum: 50}

  validates :property_description, length: {minimum: 25}

  validates :asking_price, :bedrooms, numericality: {greater_than_or_equal_to: 0}

  validates :image_file_name, allow_blank: true, format: {
      with: /\w+.(gif|jpg|png)\z/i,
      message: "must reference a GIF, JPG, or PNG image"
  }

  SALE_STATUS = ["For Sale", "For Rent"]

  validates :sale_status, inclusion: {in: SALE_STATUS}

  def self.for_sale
    where("sale_status = 'For Sale'")
  end

  def self.for_rent
    where("sale_status = 'For Rent'")
  end

  def self.all_properties_total
    count
  end

  def self.cached_all_properties_total
    Rails.cache.fetch([self, 'cache_key_for_properties_total']) { count }
  end

  def self.for_sale_total
    where("sale_status = 'For Sale'").count
  end

  def self.cached_for_sale_total
    Rails.cache.fetch([self, 'cache_key_for_sale_total']) {where(:sale_status => 'For Sale').count }
  end

  def self.for_rent_total
    where("sale_status = 'For Rent'").count
  end

  def self.cached_for_rent_total
    Rails.cache.fetch([self, 'cached_key_for_rent_total']) {where(:sale_status => 'For Rent').count }
  end

  def self.search_for_sale(search)
    if search != ""
      where(['postcode LIKE ?', "%#{search}%"])
    else
      where("sale_status = 'For Sale'")
    end
  end

  def self.total_portfolio_value
    where("sale_status = 'For Sale'").sum(:asking_price)
  end

  #TODO refactor all these methods into single method
  def self.total_0_bedrooms
    where(:bedrooms => '0').count
  end

  def self.total_1_bedrooms
    where(:bedrooms => '1').count
  end

  def self.total_2_bedrooms
    where(:bedrooms => '2').count
  end

  def self.total_3_bedrooms
    where(:bedrooms => '3').count
  end

  def self.total_4_bedrooms
    where(:bedrooms => '4').count
  end

  def self.total_5_bedrooms
    where(:bedrooms => '5').count
  end

  # TODO fix this query
  def self.total_6_plus_bedrooms
    where(:bedrooms => '> 5').count
  end

  def self.added_today
    where("DATE(created_at) = DATE(?)", Time.now).count
  end

  attr_accessible :address_line_1, :address_line_2, :town_city, :county, :postcode, :country, :property_description, :bedrooms, :image_file_name, :sale_status, :asking_price, :user_id

end
