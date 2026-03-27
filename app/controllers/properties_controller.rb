class PropertiesController < ApplicationController
  include PropertyScoped

  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_property, only: [:show, :edit, :update, :destroy]
  before_action :authorize_property_owner!, only: [:edit, :update, :destroy]
  before_action :ensure_property_is_visible!, only: :show

  def index
    catalogue = PropertyCatalogueQuery.new(params:).call

    @filters = catalogue.filters
    @properties = catalogue.properties
    @available_towns = catalogue.available_towns
    @total_properties = catalogue.total_count
    @catalogue_totals = {
      all: Property.cached_all_properties_total,
      for_sale: Property.cached_for_sale_total,
      for_rent: Property.cached_for_rent_total
    }
    @saved_search = SavedSearch.new(saved_search_defaults)
  end

  def show
    @available_slots = @property.next_available_slots(limit: 8)
    @recent_enquiries = @property.enquiries.recent_first.limit(3)
    @recent_offers = @property.offers.recent_first.limit(3)
    @recent_rental_applications = @property.rental_applications.recent_first.limit(3)
    @public_documents = @property.public_documents
    @recent_activity = @property.activity_timeline(limit: 8)
  end

  def edit
  end

  def update
    if @property.update(property_params)
      redirect_to @property, notice: t(:successfully_updated)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @property = current_user.properties.new(listing_state: "draft")
  end

  def create
    @property = current_user.properties.new(property_params.reverse_merge(listing_state: "draft"))
    if @property.save
      redirect_to @property, notice: t(:successfully_created)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @property.destroy
    redirect_to properties_path, notice: t(:successfully_deleted)
  end

  private

  def property_params
    params.require(:property).permit(
      :address_line_1, :address_line_2, :town_city, :county, :postcode, :country,
      :property_description, :bedrooms, :bathrooms, :property_type, :listing_tagline,
      :image_file_name, :sale_status, :asking_price, :featured, :listing_state, :tenure,
      :council_tax_band, :furnishing, :available_from, :parking, :outdoor_space,
      :epc_rating, :floor_area_sq_ft, :deposit_amount, :pets_allowed, :service_charge_amount,
      :lease_length_years
    )
  end

  def set_property
    super
  end

  def ensure_property_is_visible!
    return if @property.publicly_visible?
    return if current_admin.present?
    return if current_user == @property.user

    redirect_to properties_path, alert: t("ui.properties.flash.not_public")
  end

  def saved_search_defaults
    {
      locale: I18n.locale.to_s,
      email: current_user&.email,
      sale_status: @filters[:sale_status],
      search_query: @filters[:q],
      town_city: @filters[:town_city],
      min_bedrooms: @filters[:min_bedrooms],
      min_price: @filters[:min_price],
      max_price: @filters[:max_price],
      sort: @filters[:sort],
      alerts_enabled: true
    }
  end

end
