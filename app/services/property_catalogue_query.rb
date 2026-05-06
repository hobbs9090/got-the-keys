class PropertyCatalogueQuery
  FILTER_KEYS = %i[q sale_status min_bedrooms min_price max_price town_city sort].freeze
  class UnknownTown < StandardError
    attr_reader :town

    def initialize(town)
      @town = town
      super("Unknown town: #{town}")
    end
  end

  Result = Struct.new(:filters, :scope, :properties, :available_towns, :total_count, keyword_init: true)

  def initialize(params:, relation: Property.publicly_visible, town_scope: Property.publicly_visible, page: nil, default_filters: {}, validate_town: true)
    @params = normalize_params(params)
    @relation = relation
    @town_scope = town_scope
    @page = page || @params[:page]
    @default_filters = normalize_params(default_filters)
    @validate_town = validate_town
  end

  def call
    filters = params.slice(*FILTER_KEYS).merge(default_filters.slice(*FILTER_KEYS)).symbolize_keys
    filters = remove_price_filters_without_listing_type(filters)
    available_towns = relation.model.cached_available_towns(scope: town_scope)
    filters = canonicalize_town_filter(filters, available_towns)
    scope = relation.scoping { relation.model.filter(filters) }
    properties = scope.preload(:photos, :property_documents).page(page)

    Result.new(
      filters:,
      scope:,
      properties:,
      available_towns:,
      total_count: properties.total_count
    )
  end

  private

  attr_reader :params, :relation, :town_scope, :page, :default_filters, :validate_town

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
      normalized[:town_city] = normalized[:town_city].to_s.squish.presence if normalized.key?(:town_city)
      normalized[:town] = normalized[:town].to_s.squish.presence if normalized.key?(:town)
      normalized[:town_city] = normalized[:town] if normalized[:town_city].blank? && normalized[:town].present?
    end
  end

  def normalize_price_filter(value)
    value.to_s.gsub(/[,\s]/, "").presence
  end

  def remove_price_filters_without_listing_type(filters)
    return filters if filters[:sale_status].present?

    filters.except(:min_price, :max_price)
  end

  def canonicalize_town_filter(filters, available_towns)
    town = filters[:town_city].to_s.squish.presence
    return filters.except(:town_city) if town.blank?

    match = available_towns.find { |available| available.to_s.casecmp(town).zero? }
    raise UnknownTown, town if validate_town && match.blank?

    filters.merge(town_city: match.presence || town)
  end
end
