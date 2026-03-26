class PropertyCatalogueQuery
  FILTER_KEYS = %i[q sale_status min_bedrooms min_price max_price town_city sort].freeze
  Result = Struct.new(:filters, :scope, :properties, :available_towns, :total_count, keyword_init: true)

  def initialize(params:, relation: Property.all, town_scope: Property.all, page: nil, default_filters: {})
    @params = normalize_params(params)
    @relation = relation
    @town_scope = town_scope
    @page = page || @params[:page]
    @default_filters = normalize_params(default_filters)
  end

  def call
    filters = params.slice(*FILTER_KEYS).merge(default_filters.slice(*FILTER_KEYS)).symbolize_keys
    scope = relation.scoping { relation.model.filter(filters) }
    properties = scope.page(page)

    Result.new(
      filters:,
      scope:,
      properties:,
      available_towns: town_scope.order(:town_city).distinct.pluck(:town_city),
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

    source.with_indifferent_access
  end
end
