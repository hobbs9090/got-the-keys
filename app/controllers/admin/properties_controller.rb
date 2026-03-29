class Admin::PropertiesController < Admin::BaseController
  before_action :set_property, only: %i[show edit update transition]

  def index
    @properties = Property.recommended_order.includes(:user).page(params[:page])
  end

  def show
    @appointments = @property.appointments.recent_first.limit(20)
    @availability_windows = @property.availability_windows.order(:starts_at)
    @activity_logs = @property.activity_timeline(limit: 20)
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

  def transition
    new_state = params[:listing_state].presence_in(Property::LISTING_STATES)

    unless new_state
      redirect_to admin_property_path(@property), alert: "Unsupported listing state."
      return
    end

    if @property.update(listing_state: new_state)
      AuditLogger.log!(
        auditable: @property,
        property: @property,
        admin: current_admin,
        action: "listing_state_changed",
        message: "Listing state moved to #{new_state.tr('_', ' ')}.",
        metadata: { listing_state: new_state }
      )
      redirect_back fallback_location: admin_property_path(@property), notice: "Listing moved to #{new_state.tr('_', ' ')}."
    else
      redirect_back fallback_location: admin_property_path(@property), alert: @property.errors.full_messages.to_sentence
    end
  end

  private

  def set_property
    @property = Property.find(params[:id])
  end

  def property_params
    params.require(:property).permit(
      :address_line_1, :address_line_2, :town_city, :county, :postcode, :country,
      :property_description, :bedrooms, :bathrooms, :property_type, :listing_tagline,
      :image_file_name, :sale_status, :asking_price, :featured, :listing_state, :tenure,
      :council_tax_band, :furnishing, :available_from, :parking, :outdoor_space,
      :epc_rating, :floor_area_sq_ft, :deposit_amount, :pets_allowed, :service_charge_amount,
      :lease_length_years, :year_built, :refurbished_year
    )
  end
end
