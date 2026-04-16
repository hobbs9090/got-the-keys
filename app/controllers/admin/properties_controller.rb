class Admin::PropertiesController < Admin::BaseController
  before_action :set_property, only: %i[show edit update transition]

  def index
    @query = params[:q].to_s.squish
    @listing_state = params[:listing_state].presence_in(Property::LISTING_STATES)
    @sale_status = params[:sale_status].presence_in(Property::SALE_STATUS)
    @town_city = params[:town_city].to_s.squish.presence
    @min_bedrooms = normalize_integer_param(params[:min_bedrooms])
    @min_price = normalize_integer_param(params[:min_price])
    @max_price = normalize_integer_param(params[:max_price])
    @saved_searches = personal_saved_searches
    @properties = filtered_properties
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

  def filtered_properties
    scope = Property.left_joins(:user).distinct
    scope = scope.where(listing_state: @listing_state) if @listing_state.present?
    scope = scope.where(sale_status: @sale_status) if @sale_status.present?
    scope = scope.where("LOWER(properties.town_city) = ?", @town_city.downcase) if @town_city.present?
    scope = scope.where("properties.bedrooms >= ?", @min_bedrooms) if @min_bedrooms.present?
    scope = scope.where("properties.asking_price >= ?", @min_price) if @min_price.present?
    scope = scope.where("properties.asking_price <= ?", @max_price) if @max_price.present?
    return scope if @query.blank?

    @query.split.each do |term|
      pattern = "%#{Property.sanitize_sql_like(term.downcase)}%"

      scope = scope.where(<<~SQL.squish, pattern:)
        LOWER(properties.address_line_1) LIKE :pattern
        OR LOWER(COALESCE(properties.address_line_2, '')) LIKE :pattern
        OR LOWER(properties.town_city) LIKE :pattern
        OR LOWER(properties.county) LIKE :pattern
        OR LOWER(properties.postcode) LIKE :pattern
        OR LOWER(properties.country) LIKE :pattern
        OR LOWER(properties.property_type) LIKE :pattern
        OR LOWER(COALESCE(properties.listing_tagline, '')) LIKE :pattern
        OR LOWER(properties.property_description) LIKE :pattern
        OR LOWER(properties.sale_status) LIKE :pattern
        OR LOWER(properties.listing_state) LIKE :pattern
        OR LOWER(COALESCE(users.first_name, '')) LIKE :pattern
        OR LOWER(COALESCE(users.last_name, '')) LIKE :pattern
        OR LOWER(COALESCE(users.email, '')) LIKE :pattern
        OR LOWER(COALESCE(users.first_name, '') || ' ' || COALESCE(users.last_name, '')) LIKE :pattern
      SQL
    end

    scope
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

  def normalize_integer_param(value)
    normalized = value.to_s.gsub(/[,\s]/, "")
    return if normalized.blank?
    return unless normalized.match?(/\A\d+\z/)

    normalized.to_i
  end
end
