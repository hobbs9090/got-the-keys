class PhotosController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :authenticate_user!, except: [:index]
  before_action :authorize_property_owner!, except: [:index]
  before_action :set_photo, only: [:update, :destroy]

  def index
    @photos = @property.photos.ordered
    @new_photo = @property.photos.new(default_photo_attributes)
  end

  def new
    redirect_to property_photos_path(@property)
  end

  def create
    @photos = @property.photos.ordered
    @new_photo = @property.photos.new(photo_params)
    @new_photo.primary = true if @property.photos.none?

    if @new_photo.save
      redirect_to property_photos_path(@property), notice: t("ui.photos.flash.added")
    else
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @photos = @property.photos.ordered
    @new_photo = @property.photos.new(default_photo_attributes)
    @edited_photo = @photo

    if @photo.update(photo_params)
      redirect_to property_photos_path(@property), notice: t("ui.photos.flash.updated")
    else
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @photo.destroy
    redirect_to property_photos_path(@property), notice: t("ui.photos.flash.removed")
  end

  private

  def set_photo
    @photo = @property.photos.find(params[:id])
  end

  def photo_params
    params.require(:photo).permit(:image_filename, :caption, :position, :primary)
  end

  def next_position
    @property.photos.maximum(:position).to_i + 1
  end

  def default_photo_attributes
    {
      position: next_position,
      primary: @property.photos.none?
    }
  end
end
