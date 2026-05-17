class ForRentController < ApplicationController
  include CataloguePageBounds

  def index
    catalogue = PropertyCatalogueQuery.new(
      params:,
      town_scope: Property.for_rent,
      default_filters: { sale_status: Property::SALE_STATUSES[:for_rent] }
    ).call

    @filters = catalogue.filters
    @properties = catalogue.properties
    @available_towns = catalogue.available_towns
    @total_for_rent = catalogue.total_count

    redirect_if_page_out_of_range!(@properties)
  end
end
