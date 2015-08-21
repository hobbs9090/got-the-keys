class PhotosController < ApplicationController

  before_action :set_property

  def index
    @photos = @property.photos
  end

  def new
    @photos = @property.photos.new
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

end
