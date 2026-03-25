class ForRentController < ApplicationController
  def index
    @properties = Property.for_rent.order(updated_at: :desc).page(params[:page])
    @total_for_rent = Property.for_rent_total
  end
end
