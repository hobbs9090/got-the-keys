class ForSaleController < ApplicationController
  def index
    @properties = Property.for_sale.order(updated_at: :desc).page(params[:page])
    @total_for_sale = Property.for_sale_total
  end
end
