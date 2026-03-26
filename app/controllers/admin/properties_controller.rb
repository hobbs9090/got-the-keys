class Admin::PropertiesController < Admin::BaseController
  before_action :set_property, only: %i[show edit update]

  def index
    @properties = Property.recommended_order.includes(:user).page(params[:page])
  end

  def show
    @appointments = @property.appointments.recent_first.limit(20)
    @availability_windows = @property.availability_windows.order(:starts_at)
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to admin_property_path(@property), notice: t("ui.admin.flash.property_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def property_params
    params.require(:property).permit(:address_line_1, :address_line_2, :town_city, :county, :postcode, :country, :property_description, :bedrooms, :bathrooms, :property_type, :listing_tagline, :image_file_name, :sale_status, :asking_price, :featured)
  end
end
