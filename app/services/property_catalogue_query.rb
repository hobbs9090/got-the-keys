class PropertyCatalogueQuery
  FILTER_KEYS = %i[q sale_status min_bedrooms min_price max_price town_city sort].freeze
  Result = Struct.new(:filters, :scope, :properties, :available_towns, :total_count, keyword_init: true)

  def initialize(params:, relation: Property.publicly_visible, town_scope: Property.publicly_visible, page: nil, default_filters: {})
    @params = normalize_params(params)
    @relation = relation
    @town_scope = town_scope
    @page = page || @params[:page]
    @default_filters = normalize_params(default_filters)
  end

  def call
    filters = params.slice(*FILTER_KEYS).merge(default_filters.slice(*FILTER_KEYS)).symbolize_keys
    filters = remove_price_filters_without_listing_type(filters)
    scope = relation.scoping { relation.model.filter(filters) }
    properties = scope.preload(:photos, :property_documents).page(page)

    Result.new(
      filters:,
      scope:,
      properties:,
      available_towns: relation.model.cached_available_towns(scope: town_scope),
      total_count: properties.total_count
    )
  end

  private

  attr_reader :params, :relation, :town_scope, :page, :default_filters

  def normalize_params(value)
    source =
      if defined?(ActionController::Parameters) && value.is_a?(ActionController::Parameters)
        value.to_unsafe_h
      else
        value.to_h
      end

    source.with_indifferent_access.tap do |normalized|
      %i[min_price max_price].each do |key|
        next unless normalized.key?(key)

        normalized[key] = normalize_price_filter(normalized[key])
      end
    end
  end

  def normalize_price_filter(value)
    value.to_s.gsub(/[,\s]/, "").presence
  end

  def remove_price_filters_without_listing_type(filters)
    return filters if filters[:sale_status].present?

    filters.except(:min_price, :max_price)
  end
end
