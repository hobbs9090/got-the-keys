class Admin::PropertyIndexQuery
  FILTER_KEYS = %i[q listing_state sale_status town_city min_bedrooms min_price max_price sort].freeze

  def initialize(params:)
    @filters = normalize_params(params)
  end

  def call
    base_scope.scoping { Property.filter(public_catalogue_filters) }
  end

  private

  attr_reader :filters

  def base_scope
    scope = Property.all
    scope = scope.where(listing_state: filters[:listing_state]) if filters[:listing_state].present?
    return scope if filters[:listing_state].present?
    return Property.publicly_visible if public_catalogue_filters.values.any?(&:present?)

    scope
  end

  def public_catalogue_filters
    filters.slice(:q, :sale_status, :town_city, :min_bedrooms, :min_price, :max_price, :sort)
  end

  def normalize_params(params)
    params
      .to_h
      .symbolize_keys
      .slice(*FILTER_KEYS)
      .transform_values { |value| value.is_a?(String) ? value.squish : value }
      .tap do |normalized|
        normalized[:q] = normalized[:q].presence
        normalized[:town_city] = normalized[:town_city].presence
        normalized[:sort] = normalized[:sort].presence
        %i[min_bedrooms min_price max_price].each do |key|
          normalized[key] = normalize_integer_param(normalized[key])
        end
      end
  end

  def normalize_integer_param(value)
    normalized = value.to_s.gsub(/[,\s]/, "")
    return if normalized.blank?
    return unless normalized.match?(/\A\d+\z/)

    normalized.to_i
  end
end
