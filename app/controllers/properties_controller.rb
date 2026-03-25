class PropertiesController < ApplicationController
  include PropertyScoped

  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_property, only: [:show, :edit, :update, :destroy]
  before_action :authorize_property_owner!, only: [:edit, :update, :destroy]

  def index
    @filters = property_filter_params
    @properties = Property.filter(@filters).page(params[:page])
    @available_towns = Property.order(:town_city).distinct.pluck(:town_city)
    @total_properties = @properties.total_count
  end

  def show
    @available_slots = @property.next_available_slots(limit: 8)
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property, notice: t(:successfully_updated)
    else
      render :edit
    end
  end

  def new
    @property = current_user.properties.new
  end

  def create
    @property = current_user.properties.new(property_params)
    if @property.save
      redirect_to @property, notice: t(:successfully_created)
    else
      render :new
    end
  end

  def destroy
    @property.destroy
    redirect_to properties_path, notice: t(:successfully_deleted)
  end

  private

  def property_params
    params.require(:property).permit(:address_line_1, :address_line_2, :town_city, :county, :postcode, :country, :property_description, :bedrooms, :bathrooms, :property_type, :listing_tagline, :image_file_name, :sale_status, :asking_price, :featured)
  end

  def set_property
    super
  end

  def property_filter_params
    params.permit(:q, :sale_status, :min_bedrooms, :min_price, :max_price, :town_city, :sort)
  end

end
