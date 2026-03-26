class ForSaleController < ApplicationController
  def index
    catalogue = PropertyCatalogueQuery.new(
      params:,
      town_scope: Property.for_sale,
      default_filters: { sale_status: Property::SALE_STATUSES[:for_sale] }
    ).call

    @filters = catalogue.filters
    @properties = catalogue.properties
    @available_towns = catalogue.available_towns
    @total_for_sale = catalogue.total_count
  end
end
