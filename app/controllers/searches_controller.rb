class SearchesController < ApplicationController
  def index
    @sale_status = params[:sale_status].presence_in(Property::SALE_STATUS) || Property::SALE_STATUSES[:for_sale]
    @properties = Property.search(params[:q], sale_status: @sale_status).page(params[:page])
    @number_search_results = Property.search(params[:q], sale_status: @sale_status)
  end

  def search_for_sale
    @properties = Property.search_for_sale(params[:q]).page(params[:page])
  end
end
