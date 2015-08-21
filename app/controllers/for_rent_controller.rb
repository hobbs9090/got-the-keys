class ForRentController < ApplicationController

  def index
    @properties = Property.for_rent.page(params[:page]).order(:id)
    @total_for_rent = Property.for_rent_total
    #@total_for_rent = Property.cached_for_rent_total
  end

end
