class Property < ApplicationRecord
  paginates_per 12

  SALE_STATUSES = {
    for_sale: 'For Sale',
    for_rent: 'For Rent'
  }.freeze
  SALE_STATUS = SALE_STATUSES.values.freeze
  SORT_OPTIONS = %w[recommended newest price_low price_high bedrooms_high].freeze

  belongs_to :user, counter_cache: true

  has_many :photos, dependent: :destroy
  has_many :floor_plans, dependent: :destroy
  has_many :viewing_times, dependent: :destroy
  has_many :availability_windows, dependent: :destroy
  has_many :appointments, dependent: :destroy

  validates :address_line_1, :town_city, :county, :postcode, :country,
            :property_description, :bedrooms, :sale_status, :asking_price,
            :user_id, presence: true
  validates :property_type, presence: true, length: { maximum: 50 }
  validates :address_line_1, :address_line_2, :town_city, :county, :postcode,
            :country, length: { maximum: 50 }
  validates :listing_tagline, length: { maximum: 120 }, allow_blank: true
  validates :property_description, length: { minimum: 25, maximum: 5000 }, allow_blank: true
  validates :asking_price, :bedrooms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_blank: true
  validates :bathrooms, presence: true
  validates :bathrooms, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_blank: true
  validates :image_file_name,
            allow_blank: true,
            format: {
              with: /\w+\.(gif|jpg|png|svg)\z/i,
              message: 'must reference a GIF, JPG, PNG, or SVG image'
            }
  validates :sale_status, inclusion: { in: SALE_STATUS }, allow_blank: true

  scope :for_sale, -> { where(sale_status: SALE_STATUSES[:for_sale]) }
  scope :for_rent, -> { where(sale_status: SALE_STATUSES[:for_rent]) }
  scope :featured, -> { where(featured: true) }
  scope :recommended_order, -> { order(featured: :desc, updated_at: :desc) }

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
      filter(q: query, sale_status: sale_status)
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

    def filter(filters = {})
      filters = filters.to_h.symbolize_keys
      listings = all
      listings = listings.where(sale_status: filters[:sale_status]) if filters[:sale_status].present?

      if filters[:q].present?
        sanitized_query = "%#{sanitize_sql_like(filters[:q])}%"
        listings = listings.where(
          'address_line_1 LIKE :query OR town_city LIKE :query OR county LIKE :query OR postcode LIKE :query OR property_description LIKE :query',
          query: sanitized_query
        )
      end

      listings = listings.where('bedrooms >= ?', filters[:min_bedrooms].to_i) if filters[:min_bedrooms].present?
      listings = listings.where('asking_price >= ?', filters[:min_price].to_i) if filters[:min_price].present?
      listings = listings.where('asking_price <= ?', filters[:max_price].to_i) if filters[:max_price].present?
      listings = listings.where(town_city: filters[:town_city]) if filters[:town_city].present?

      case filters[:sort]
      when 'price_low'
        listings.order(asking_price: :asc, updated_at: :desc)
      when 'price_high'
        listings.order(asking_price: :desc, updated_at: :desc)
      when 'bedrooms_high'
        listings.order(bedrooms: :desc, asking_price: :asc)
      when 'newest'
        listings.order(updated_at: :desc)
      else
        listings.order(featured: :desc, updated_at: :desc)
      end
    end
  end

  def headline
    listing_tagline.presence || I18n.t("ui.properties.headline_fallback", property_type:, town_city:)
  end

  def location_line
    [town_city, county].reject(&:blank?).join(', ')
  end

  def next_available_slots(limit: 6, from: Time.current)
    AppointmentAvailability.new(property: self, from: from).next_slots(limit: limit)
  end
end
