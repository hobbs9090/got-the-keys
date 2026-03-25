class Property < ApplicationRecord
  SALE_STATUSES = {
    for_sale: 'For Sale',
    for_rent: 'For Rent'
  }.freeze
  SALE_STATUS = SALE_STATUSES.values.freeze

  belongs_to :user, counter_cache: true

  has_many :photos, dependent: :destroy
  has_many :floor_plans, dependent: :destroy
  has_many :viewing_times, dependent: :destroy

  validates :address_line_1, :town_city, :county, :postcode, :country,
            :property_description, :bedrooms, :sale_status, :asking_price,
            :user_id, presence: true
  validates :address_line_1, :address_line_2, :town_city, :county, :postcode,
            :country, length: { maximum: 50 }
  validates :property_description, length: { minimum: 25 }
  validates :asking_price, :bedrooms, numericality: { greater_than_or_equal_to: 0 }
  validates :image_file_name,
            allow_blank: true,
            format: {
              with: /\w+\.(gif|jpg|png)\z/i,
              message: 'must reference a GIF, JPG, or PNG image'
            }
  validates :sale_status, inclusion: { in: SALE_STATUS }

  scope :for_sale, -> { where(sale_status: SALE_STATUSES[:for_sale]) }
  scope :for_rent, -> { where(sale_status: SALE_STATUSES[:for_rent]) }

  class << self
    def all_properties_total
      count
    end

    def cached_all_properties_total
      Rails.cache.fetch([name, 'all_properties_total', maximum(:updated_at)]) { count }
    end

    def for_sale_total
      for_sale.count
    end

    def cached_for_sale_total
      Rails.cache.fetch([name, 'for_sale_total', maximum(:updated_at)]) { for_sale.count }
    end

    def for_rent_total
      for_rent.count
    end

    def cached_for_rent_total
      Rails.cache.fetch([name, 'for_rent_total', maximum(:updated_at)]) { for_rent.count }
    end

    def search(query, sale_status:)
      listings = where(sale_status: sale_status)
      return listings if query.blank?

      sanitized_query = "%#{sanitize_sql_like(query)}%"
      listings.where(
        'address_line_1 LIKE :query OR town_city LIKE :query OR postcode LIKE :query',
        query: sanitized_query
      )
    end

    def search_for_sale(query)
      search(query, sale_status: SALE_STATUSES[:for_sale])
    end

    def search_for_rent(query)
      search(query, sale_status: SALE_STATUSES[:for_rent])
    end

    def total_portfolio_value
      for_sale.sum(:asking_price)
    end

    def total_0_bedrooms
      where(bedrooms: 0).count
    end

    def total_1_bedrooms
      where(bedrooms: 1).count
    end

    def total_2_bedrooms
      where(bedrooms: 2).count
    end

    def total_3_bedrooms
      where(bedrooms: 3).count
    end

    def total_4_bedrooms
      where(bedrooms: 4).count
    end

    def total_5_bedrooms
      where(bedrooms: 5).count
    end

    def total_6_plus_bedrooms
      where('bedrooms > ?', 5).count
    end

    def added_today
      where(created_at: Time.current.all_day).count
    end
  end
end
