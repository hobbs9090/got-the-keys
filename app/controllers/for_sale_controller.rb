class ForSaleController < ApplicationController

  def index
    @properties = Property.for_sale.page(params[:page]).order(:id)
    @total_for_sale = Property.for_sale_total
    #@total_for_sale = Property.cached_for_sale_total
  end

end
