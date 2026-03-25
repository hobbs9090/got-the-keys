class PhotosController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :authenticate_user!, only: [:new]
  before_action :authorize_property_owner!, only: [:new]

  def index
    @photos = @property.photos
  end

  def new
    @photos = @property.photos.new
  end

  private
end
