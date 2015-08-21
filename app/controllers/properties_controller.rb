class PropertiesController < ApplicationController

  before_action :authenticate_user!, except: [:index, :show]

  before_action :authenticate_user!, except: [:index, :show]

  before_action :set_user

  def index
    @properties = Property.page(params[:page]).order(:id)
    @total_properties = Property.all_properties_total
  end

  def show
    @property = Property.find(params[:id])
  end

  def edit
    if Property.find(params[:id]).user_id == @user.id
      @property = Property.find(params[:id])
    else
      redirect_to root_path, alert: t(:not_authorised)
    end
  end

  def update
    @property = Property.find(params[:id])
    if @property.update(property_params)
      redirect_to @property, notice: t(:successfully_updated)
    else
      render :edit
    end
  end

  def new
    @property = @user.properties.new
  end

  def create
    @property = @user.properties.new(property_params)
    if @property.save(property_params)
      redirect_to @property, notice: t(:successfully_created)
    else
      render :new
    end
  end

  def destroy
    @property = Property.find(params[:id])
    @property.destroy
    redirect_to properties_path, notice: t(:successfully_deleted)
  end

  private

  def property_params
    params.require(:property).permit(:address_line_1, :address_line_2, :town_city, :county, :postcode, :country, :property_description, :bedrooms, :image_file_name, :sale_status, :asking_price, :user_id)
  end

  def set_user
    @user = current_user
  end

end
