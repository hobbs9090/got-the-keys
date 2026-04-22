class LocationController < ApplicationController

  def show
    @property = Property.publicly_visible.find(params[:id])
  end

end
