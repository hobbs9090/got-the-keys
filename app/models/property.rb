require "fileutils"

class Property < ApplicationRecord
  paginates_per 12

  IMAGE_FILE_NAME_FORMAT = /\A[\w.\-\/ ]+\.(gif|jpg|jpeg|png|svg)\z/i.freeze
  IMAGE_UPLOAD_EXTENSIONS = %w[.jpg .jpeg].freeze
  IMAGE_UPLOAD_CONTENT_TYPES = %w[image/jpeg image/pjpeg image/jpg].freeze
  UPLOADED_IMAGE_PREFIX = "/uploads/property_images/".freeze

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

  attr_accessor :image_upload

  def asking_price=(value)
    super(normalize_integer_input(value))
  end

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
              with: IMAGE_FILE_NAME_FORMAT,
              message: ->(_record, _data) { I18n.t("ui.properties.validation.image_file_name", default: "must reference a GIF, JPG, JPEG, PNG, or SVG image") }
            }
  validates :sale_status, inclusion: { in: SALE_STATUS }, allow_blank: true
  validates :listing_state, inclusion: { in: LISTING_STATES }
  validates :tenure, :council_tax_band, :furnishing, :parking, :outdoor_space, length: { maximum: 60 }, allow_blank: true
  validates :floor_area_sq_ft, :deposit_amount, :service_charge_amount, :lease_length_years,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_blank: true
  validates :year_built, :refurbished_year,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1700,
              less_than_or_equal_to: Date.current.year + 1
            },
            allow_blank: true

  before_validation :apply_listing_defaults
  before_validation :clear_furnishing_for_sale_listings
  before_validation :clear_rental_only_fields_for_sale_listings
  before_validation :clear_lease_length_for_freehold_sale_listings
  validate :refurbished_year_not_before_year_built
  validate :image_upload_is_jpeg
  validate :prevent_duplicate_exact_address
  after_destroy_commit :remove_uploaded_image_file

  scope :for_sale, -> { where(sale_status: SALE_STATUSES[:for_sale]) }
  scope :for_rent, -> { where(sale_status: SALE_STATUSES[:for_rent]) }
  scope :featured, -> { where(featured: true) }
  scope :publicly_visible, -> { where(listing_state: PUBLIC_LISTING_STATES) }
  scope :recommended_order, -> { order(Arel.sql(media_priority_order_sql)).order(featured: :desc, updated_at: :desc) }

  class << self
    def media_priority_order_sql
      <<~SQL.squish
        CASE
          WHEN NULLIF(properties.image_file_name, '') IS NOT NULL THEN 1
          WHEN EXISTS (
            SELECT 1
            FROM photos
            WHERE photos.property_id = properties.id
          ) THEN 1
          ELSE 0
        END DESC
      SQL
    end

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
        listings.order(Arel.sql(media_priority_order_sql)).order(featured: :desc, updated_at: :desc)
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
    ordered_photos.first
  end

  def ordered_photos
    return photos.sort_by { |photo| [photo.primary? ? 0 : 1, photo.position, photo.id] } if association(:photos).loaded?

    photos.ordered
  end

  def ordered_floor_plans
    return floor_plans.sort_by { |floor_plan| [floor_plan.position, floor_plan.id] } if association(:floor_plans).loaded?

    floor_plans.ordered
  end

  def ordered_documents
    return property_documents.sort_by { |document| [document.position, document.id] } if association(:property_documents).loaded?

    property_documents.ordered
  end

  def public_documents
    return ordered_documents.select(&:publicly_visible?) if association(:property_documents).loaded?

    property_documents.publicly_visible.ordered
  end

  def hero_image_name
    primary_photo&.image_filename.presence || image_file_name
  end

  def persist_image_upload!
    return if image_upload.blank? || !persisted?

    extension = File.extname(image_upload.original_filename.to_s).downcase
    filename = "#{SecureRandom.hex(16)}#{extension}"
    relative_path = File.join("property_images", id.to_s, filename)
    absolute_path = image_upload_root.join(relative_path)
    previous_image_path = image_file_name if uploaded_property_image_path?(image_file_name)

    FileUtils.mkdir_p(absolute_path.dirname)
    image_upload.rewind if image_upload.respond_to?(:rewind)
    File.binwrite(absolute_path, image_upload.read)

    new_image_path = "/uploads/#{relative_path}"
    update_column(:image_file_name, new_image_path)
    self.image_file_name = new_image_path
    self.image_upload = nil

    purge_uploaded_image(previous_image_path) if previous_image_path.present? && previous_image_path != new_image_path
  end

  def listing_completeness_checks
    [
      {
        key: :headline,
        label: I18n.t("ui.properties.seller.checks.headline"),
        complete: listing_tagline.present? && property_description.to_s.length >= 80
      },
      {
        key: :media,
        label: I18n.t("ui.properties.seller.checks.media"),
        complete: ordered_photos.any? || image_file_name.present?
      },
      {
        key: :floor_plan,
        label: I18n.t("ui.properties.seller.checks.floor_plan"),
        complete: ordered_floor_plans.any?
      },
      {
        key: :facts,
        label: I18n.t("ui.properties.seller.checks.facts"),
        complete: [tenure, council_tax_band, floor_area_sq_ft].all?(&:present?)
      },
      {
        key: :contact,
        label: I18n.t("ui.properties.seller.checks.contact"),
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

  def normalize_integer_input(value)
    value.to_s.gsub(/[,\s]/, "").presence
  end

  def image_upload_is_jpeg
    return if image_upload.blank?

    extension = File.extname(image_upload.original_filename.to_s).downcase
    content_type = image_upload.content_type.to_s

    return if extension.in?(IMAGE_UPLOAD_EXTENSIONS) && (content_type.blank? || content_type.in?(IMAGE_UPLOAD_CONTENT_TYPES))

    errors.add(:image_upload, I18n.t("ui.properties.validation.image_upload", default: "must be a JPG or JPEG image"))
  end

  def image_upload_root
    if Rails.env.test?
      Rails.root.join("tmp", "uploads")
    else
      Rails.root.join("public", "uploads")
    end
  end

  def uploaded_property_image_path?(path)
    path.to_s.start_with?(UPLOADED_IMAGE_PREFIX)
  end

  def uploaded_image_absolute_path(path)
    return if path.blank? || !uploaded_property_image_path?(path)

    image_upload_root.join(path.delete_prefix("/uploads/"))
  end

  def purge_uploaded_image(path)
    absolute_path = uploaded_image_absolute_path(path)
    return if absolute_path.blank? || !absolute_path.exist?

    absolute_path.delete
    prune_empty_upload_directories_from(absolute_path.dirname)
  end

  def prune_empty_upload_directories_from(directory)
    root_directory = image_upload_root.join("property_images")
    current_directory = directory

    while current_directory.to_s.start_with?(root_directory.to_s) && current_directory.exist? && current_directory.children.empty?
      parent_directory = current_directory.dirname
      current_directory.rmdir
      current_directory = parent_directory
    end
  end

  def remove_uploaded_image_file
    purge_uploaded_image(image_file_name)
  end

  def apply_listing_defaults
    self.listing_state ||= "published"
    self.published_at ||= Time.current if listing_state.in?(PUBLIC_LISTING_STATES) && published_at.blank?
  end

  def clear_furnishing_for_sale_listings
    self.furnishing = nil if sale_status == SALE_STATUSES[:for_sale]
  end

  def clear_rental_only_fields_for_sale_listings
    return unless sale_status == SALE_STATUSES[:for_sale]

    self.deposit_amount = nil
    self.pets_allowed = false
  end

  def clear_lease_length_for_freehold_sale_listings
    return unless sale_status == SALE_STATUSES[:for_sale]
    return unless tenure.to_s.strip.casecmp("Freehold").zero?

    self.lease_length_years = nil
  end

  def refurbished_year_not_before_year_built
    return if refurbished_year.blank? || year_built.blank?
    return if refurbished_year >= year_built

    errors.add(:refurbished_year, I18n.t("ui.properties.validation.refurbished_year", default: "must be greater than or equal to the year built"))
  end

  def prevent_duplicate_exact_address
    return if address_line_1.blank? || postcode.blank? || country.blank?

    duplicate_scope = self.class.where(
      <<~SQL.squish,
        LOWER(TRIM(address_line_1)) = :address_line_1
        AND LOWER(TRIM(COALESCE(address_line_2, ''))) = :address_line_2
        AND REPLACE(LOWER(postcode), ' ', '') = :postcode
        AND LOWER(TRIM(country)) = :country
      SQL
      address_line_1: normalized_address_component(address_line_1),
      address_line_2: normalized_address_component(address_line_2),
      postcode: normalized_postcode(postcode),
      country: normalized_address_component(country)
    )

    duplicate_scope = duplicate_scope.where.not(id: id) if persisted?
    return unless duplicate_scope.exists?

    errors.add(:address_line_1, I18n.t("ui.properties.validation.duplicate_address", default: "has already been listed for this address"))
  end

  def normalized_address_component(value)
    value.to_s.strip.downcase
  end

  def normalized_postcode(value)
    value.to_s.gsub(/\s+/, "").downcase
  end
end
