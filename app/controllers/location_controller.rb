class LocationController < ApplicationController

  def show
    @property = Property.find(params[:id])
  end

end
