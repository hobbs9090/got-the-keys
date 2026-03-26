class Property < ApplicationRecord
  paginates_per 12

  SALE_STATUSES = {
    for_sale: 'For Sale',
    for_rent: 'For Rent'
  }.freeze
  SALE_STATUS = SALE_STATUSES.values.freeze
  LISTING_STATES = %w[draft review_pending published under_offer let_agreed sold let withdrawn].freeze
  PUBLIC_LISTING_STATES = %w[published under_offer let_agreed].freeze
  SORT_OPTIONS = %w[recommended newest price_low price_high bedrooms_high].freeze

  belongs_to :user, counter_cache: true

  has_many :photos, dependent: :destroy
  has_many :floor_plans, dependent: :destroy
  has_many :property_documents, dependent: :destroy
  has_many :viewing_times, dependent: :destroy
  has_many :availability_windows, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :enquiries, dependent: :destroy
  has_many :offers, dependent: :destroy
  has_many :rental_applications, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

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
  validates :listing_state, inclusion: { in: LISTING_STATES }
  validates :tenure, :council_tax_band, :furnishing, :parking, :outdoor_space, :epc_rating, length: { maximum: 60 }, allow_blank: true
  validates :floor_area_sq_ft, :deposit_amount, :service_charge_amount, :lease_length_years,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_blank: true

  before_validation :apply_listing_defaults

  scope :for_sale, -> { where(sale_status: SALE_STATUSES[:for_sale]) }
  scope :for_rent, -> { where(sale_status: SALE_STATUSES[:for_rent]) }
  scope :featured, -> { where(featured: true) }
  scope :publicly_visible, -> { where(listing_state: PUBLIC_LISTING_STATES) }
  scope :recommended_order, -> { order(featured: :desc, updated_at: :desc) }

  class << self
    def all_properties_total
      publicly_visible.count
    end

    def cached_all_properties_total
      Rails.cache.fetch([name, 'all_properties_total', publicly_visible.maximum(:updated_at)]) { publicly_visible.count }
    end

    def for_sale_total
      publicly_visible.for_sale.count
    end

    def cached_for_sale_total
      Rails.cache.fetch([name, 'for_sale_total', publicly_visible.maximum(:updated_at)]) { publicly_visible.for_sale.count }
    end

    def for_rent_total
      publicly_visible.for_rent.count
    end

    def cached_for_rent_total
      Rails.cache.fetch([name, 'for_rent_total', publicly_visible.maximum(:updated_at)]) { publicly_visible.for_rent.count }
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

  def publicly_visible?
    listing_state.in?(PUBLIC_LISTING_STATES)
  end

  def listing_state_humanized
    listing_state.to_s.tr("_", " ").humanize
  end

  def available_now?
    available_from.blank? || available_from <= Date.current
  end

  def primary_photo
    photos.ordered.first
  end

  def ordered_photos
    photos.ordered
  end

  def ordered_floor_plans
    floor_plans.ordered
  end

  def ordered_documents
    property_documents.ordered
  end

  def public_documents
    property_documents.publicly_visible.ordered
  end

  def hero_image_name
    primary_photo&.image_filename.presence || image_file_name
  end

  def listing_completeness_checks
    [
      {
        key: :headline,
        label: "Headline and summary",
        complete: listing_tagline.present? && property_description.to_s.length >= 80
      },
      {
        key: :media,
        label: "Photography",
        complete: ordered_photos.any? || image_file_name.present?
      },
      {
        key: :floor_plan,
        label: "Floor plan",
        complete: ordered_floor_plans.any?
      },
      {
        key: :facts,
        label: "Key facts",
        complete: [tenure, council_tax_band, epc_rating, floor_area_sq_ft].all?(&:present?)
      },
      {
        key: :contact,
        label: "Contact readiness",
        complete: user.email.present? && user.mobile_number.present?
      }
    ]
  end

  def listing_completeness_score
    listing_completeness_checks.count { |check| check.fetch(:complete) }
  end

  def listing_completeness_percentage
    ((listing_completeness_score.to_f / listing_completeness_checks.size) * 100).round
  end

  def ready_for_review?
    listing_completeness_checks.all? { |check| check.fetch(:complete) }
  end

  def next_available_slots(limit: 6, from: Time.current, excluding_appointment: nil)
    AppointmentAvailability.new(property: self, from: from).next_slots(limit: limit, excluding_appointment:)
  end

  def activity_timeline(limit: nil)
    timeline = audit_logs.recent_first
    limit.present? ? timeline.limit(limit) : timeline
  end

  def recently_updated?
    updated_at.present? && updated_at >= 7.days.ago
  end

  def stale_listing?
    updated_at.present? && updated_at < 21.days.ago
  end

  private

  def apply_listing_defaults
    self.listing_state ||= "published"
    self.published_at ||= Time.current if listing_state.in?(PUBLIC_LISTING_STATES) && published_at.blank?
  end
end
