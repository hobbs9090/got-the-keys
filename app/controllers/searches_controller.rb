class SearchesController < ApplicationController
  def index
    @sale_status = params[:sale_status].presence_in(Property::SALE_STATUS) || Property::SALE_STATUSES[:for_sale]
    catalogue = PropertyCatalogueQuery.new(params:, default_filters: { sale_status: @sale_status }).call

    @filters = catalogue.filters
    @properties = catalogue.properties
    @number_search_results = catalogue.scope
    @available_towns = catalogue.available_towns
  end

  def search_for_sale
    @properties = Property.search_for_sale(params[:q]).page(params[:page])
  end
end
