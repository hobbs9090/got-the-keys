class ForSaleController < ApplicationController
  def index
    @filters = params.permit(:q, :min_bedrooms, :min_price, :max_price, :town_city, :sort).merge(sale_status: Property::SALE_STATUSES[:for_sale])
    @properties = Property.filter(@filters).page(params[:page])
    @available_towns = Property.for_sale.order(:town_city).distinct.pluck(:town_city)
    @total_for_sale = @properties.total_count
  end
end
