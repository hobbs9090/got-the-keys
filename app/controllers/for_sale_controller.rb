class ForSaleController < ApplicationController
  include CataloguePageBounds

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

    redirect_if_page_out_of_range!(@properties)
  end
end
