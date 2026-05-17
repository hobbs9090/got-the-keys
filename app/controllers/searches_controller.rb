class SearchesController < ApplicationController
  include CataloguePageBounds

  def index
    @sale_status = params[:sale_status].presence_in(Property::SALE_STATUS)
    default_filters = @sale_status.present? ? { sale_status: @sale_status } : {}
    catalogue = PropertyCatalogueQuery.new(params:, default_filters:).call

    @filters = catalogue.filters
    @properties = catalogue.properties
    @number_search_results = catalogue.scope
    @available_towns = catalogue.available_towns

    redirect_if_page_out_of_range!(@properties)
  end

  def search_for_sale
    @properties = Property.search_for_sale(params[:q]).page(params[:page])
  end
end
