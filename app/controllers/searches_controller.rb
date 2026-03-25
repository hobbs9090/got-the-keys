class SearchesController < ApplicationController
  def index
    @sale_status = params[:sale_status].presence_in(Property::SALE_STATUS) || Property::SALE_STATUSES[:for_sale]
    @filters = params.permit(:q, :min_bedrooms, :min_price, :max_price, :town_city, :sort).merge(sale_status: @sale_status)
    @properties = Property.filter(@filters).page(params[:page])
    @number_search_results = Property.filter(@filters)
    @available_towns = Property.order(:town_city).distinct.pluck(:town_city)
  end

  def search_for_sale
    @properties = Property.search_for_sale(params[:q]).page(params[:page])
  end
end
