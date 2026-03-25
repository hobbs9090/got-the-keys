class PropertiesController < ApplicationController
  include PropertyScoped

  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_property, only: [:show, :edit, :update, :destroy]
  before_action :authorize_property_owner!, only: [:edit, :update, :destroy]

  def index
    @properties = Property.order(updated_at: :desc).page(params[:page])
    @total_properties = Property.all_properties_total
  end

  def show
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
    params.require(:property).permit(:address_line_1, :address_line_2, :town_city, :county, :postcode, :country, :property_description, :bedrooms, :image_file_name, :sale_status, :asking_price)
  end

  def set_property
    super
  end

end
