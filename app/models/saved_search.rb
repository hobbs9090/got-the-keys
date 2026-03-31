class SavedSearch < ApplicationRecord
  def min_price=(value)
    super(normalize_price_value(value))
  end

  def max_price=(value)
    super(normalize_price_value(value))
  end

  validates :email, :locale, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :sale_status, inclusion: { in: Property::SALE_STATUS }, allow_blank: true
  validates :sort, inclusion: { in: Property::SORT_OPTIONS }, allow_blank: true
  validates :min_bedrooms, :min_price, :max_price,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_blank: true
  validate :price_bounds_make_sense

  before_validation :apply_defaults

  def filter_params
    {
      q: search_query,
      sale_status: sale_status,
      town_city: town_city,
      min_bedrooms: min_bedrooms,
      min_price: min_price,
      max_price: max_price,
      sort: sort
    }.compact_blank
  end

  def matching_properties_count
    PropertyCatalogueQuery.new(params: filter_params).call.total_count
  end

  private

  def apply_defaults
    self.locale ||= I18n.default_locale.to_s
  end

  def price_bounds_make_sense
    return if min_price.blank? || max_price.blank?
    return if max_price >= min_price

    errors.add(:max_price, I18n.t("ui.saved_searches.validation.max_price"))
  end

  def normalize_price_value(value)
    value.to_s.gsub(/[,\s]/, "").presence
  end
end
