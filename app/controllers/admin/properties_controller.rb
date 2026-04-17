class Admin::PropertiesController < Admin::BaseController
  before_action :set_property, only: %i[show edit update transition]

  def index
    query_filters = property_index_filters
    @query = query_filters[:q]
    @listing_state = query_filters[:listing_state]
    @sale_status = query_filters[:sale_status]
    @town_city = query_filters[:town_city]
    @min_bedrooms = query_filters[:min_bedrooms]
    @min_price = query_filters[:min_price]
    @max_price = query_filters[:max_price]
    @saved_searches = personal_saved_searches
    @properties = filtered_properties(query_filters)
      .recommended_order
      .preload(:user, :appointments, :photos, :floor_plans)
      .page(params[:page])
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
      @property.persist_image_upload! if @property.image_upload.present?
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
      :image_file_name, :image_upload, :sale_status, :asking_price, :featured, :listing_state, :tenure,
      :council_tax_band, :furnishing, :available_from, :parking, :outdoor_space,
      :floor_area_sq_ft, :deposit_amount, :pets_allowed, :service_charge_amount,
      :lease_length_years, :year_built, :refurbished_year
    )
  end

  def filtered_properties(filters = property_index_filters)
    Admin::PropertyIndexQuery.new(params: filters).call
  end

  def personal_saved_searches
    owner = saved_search_owner_user
    return SavedSearch.none if owner.blank?

    owner.saved_searches
      .includes(:user)
      .where(alerts_enabled: true)
      .where("saved_searches.created_at >= ?", 90.days.ago)
      .order(created_at: :desc)
      .limit(12)
  end

  def saved_search_owner_user
    return current_user if current_user.present?
    return if current_admin.blank?

    User.find_by(email: current_admin.email)
  end

  def property_index_filters
    {
      q: params[:q].to_s.squish.presence,
      listing_state: params[:listing_state].presence_in(Property::LISTING_STATES),
      sale_status: params[:sale_status].presence_in(Property::SALE_STATUS),
      town_city: params[:town_city].to_s.squish.presence,
      min_bedrooms: params[:min_bedrooms],
      min_price: params[:min_price],
      max_price: params[:max_price],
      sort: params[:sort].presence_in(Property::SORT_OPTIONS)
    }
  end
end
