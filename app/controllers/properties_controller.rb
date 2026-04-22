class PropertiesController < ApplicationController
  include PropertyScoped

  PROPERTY_SHOW_SLOT_LIMIT = AppointmentsController::BOOKING_FORM_SLOT_LIMIT

  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_property, only: [:show, :edit, :update, :destroy]
  before_action :authorize_property_owner!, only: [:edit, :update, :destroy]
  before_action :ensure_property_is_visible!, only: :show

  def index
    catalogue = PropertyCatalogueQuery.new(params:).call

    @filters = catalogue.filters
    @properties = catalogue.properties.load
    @next_available_slots_by_property_id = PropertyNextAvailableSlotLookup.new(properties: @properties).call
    @available_towns = catalogue.available_towns
    @total_properties = catalogue.total_count
    @catalogue_totals = {
      all: Property.cached_all_properties_total,
      for_sale: Property.cached_for_sale_total,
      for_rent: Property.cached_for_rent_total
    }
    @saved_search = SavedSearch.new(saved_search_defaults)
    @saved_searches = current_user.saved_searches.order(created_at: :desc) if user_signed_in?
    store_location_for(:user, request.fullpath) unless user_signed_in?
  end

  def show
    @appointment = @property.appointments.new(
      booking_form_defaults.merge(
        requested_time: preselected_slot,
        scheduled_at: preselected_slot,
        duration_minutes: booking_configuration.slot_duration_minutes
      )
    )
    @available_slots = @property.next_available_slots(limit: PROPERTY_SHOW_SLOT_LIMIT)
    populate_show_supporting_state
  end

  def mine
    owner_properties = current_user.properties

    @workspace_counts = {
      total: owner_properties.count,
      drafts: owner_properties.where(listing_state: %w[draft review_pending]).count,
      live: owner_properties.where(listing_state: Property::PUBLIC_LISTING_STATES).count
    }
    @saved_properties = current_user.saved_listings.preload(:photos).order(updated_at: :desc)
    @saved_searches = current_user.saved_searches.order(created_at: :desc)
    @properties = owner_properties.preload(:photos).order(updated_at: :desc).page(params[:page])
    @appointments_by_property = appointments_by_property_for(@properties)
    @customer_appointment_buckets = customer_appointment_buckets_for(current_user)
    @customer_offers = customer_offers_for(current_user)
    @customer_rental_applications = customer_rental_applications_for(current_user)
  end

  def edit
  end

  def update
    if @property.update(property_params)
      @property.persist_image_upload! if @property.image_upload.present?
      redirect_to @property, notice: t(:successfully_updated)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    @property = current_user.properties.new(default_property_attributes)
  end

  def create
    @property = current_user.properties.new(property_params.reverse_merge(default_property_attributes))
    if @property.save
      @property.persist_image_upload! if @property.image_upload.present?
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
      :image_file_name, :image_upload, :asking_price, :tenure,
      :council_tax_band, :furnishing, :available_from, :parking, :outdoor_space,
      :floor_area_sq_ft, :deposit_amount, :pets_allowed, :service_charge_amount,
      :lease_length_years, :year_built, :refurbished_year
    ).merge(seller_listing_state_params)
  end

  def seller_listing_state_params
    state = params.dig(:property, :listing_state)
    return {} if state.blank?
    return {} unless state.to_s.in?(Property::SELLER_ALLOWED_LISTING_STATES)

    { listing_state: state }
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

  def default_property_attributes
    {
      listing_state: "draft",
      country: "United Kingdom",
      sale_status: Property::SALE_STATUSES[:for_sale],
      featured: false
    }
  end

  def appointments_by_property_for(properties)
    property_ids = properties.map(&:id)
    return {} if property_ids.empty?

    appointments = Appointment.where(property_id: property_ids).to_a

    grouped = appointments.each_with_object({}) do |appointment, acc|
      buckets = acc[appointment.property_id] ||= empty_appointment_buckets
      bucket_appointment!(buckets, appointment)
    end
    grouped.each_value { |buckets| sort_appointment_buckets!(buckets) }
    grouped
  end

  def customer_appointment_buckets_for(user)
    appointments = Appointment.includes(:property)
      .where(customer_appointment_match_clause(user), **customer_appointment_match_params(user))
      .to_a

    return empty_appointment_buckets if appointments.empty?

    grouped = appointments.each_with_object(empty_appointment_buckets) do |appointment, acc|
      next if appointment.property.blank?

      bucket_appointment!(acc, appointment)
    end
    sort_appointment_buckets!(grouped)
  end

  def customer_offers_for(user)
    return [] if user.email.blank?

    Offer.includes(:property)
      .where("lower(buyer_email) = ?", user.email.downcase)
      .recent_first
      .to_a
      .select { |offer| offer.property.present? }
  end

  def customer_rental_applications_for(user)
    return [] if user.email.blank?

    RentalApplication.includes(:property)
      .where("lower(applicant_email) = ?", user.email.downcase)
      .recent_first
      .to_a
      .select { |rental_application| rental_application.property.present? }
  end

  def empty_appointment_buckets
    {
      upcoming: [],
      previous: [],
      cancelled: []
    }
  end

  def bucket_appointment!(grouped, appointment)
    if appointment.status == "cancelled"
      grouped[:cancelled] << appointment
    elsif appointment.scheduled_at >= Time.current
      grouped[:upcoming] << appointment
    else
      grouped[:previous] << appointment
    end
  end

  def sort_appointment_buckets!(buckets)
    %i[upcoming previous cancelled].each do |key|
      buckets[key].sort_by! { |appointment| [appointment.scheduled_at, appointment.id] }
    end
    buckets
  end

  def customer_appointment_match_clause(user)
    clauses = []

    clauses << "lower(customer_email) = :email" if user.email.present?

    if user.full_name.present? && user.mobile_number.present?
      clauses << "(lower(customer_name) = :customer_name AND customer_phone = :customer_phone)"
    end

    return "1 = 0" if clauses.empty?

    clauses.join(" OR ")
  end

  def customer_appointment_match_params(user)
    params = {}

    params[:email] = user.email.downcase if user.email.present?

    if user.full_name.present? && user.mobile_number.present?
      params[:customer_name] = user.full_name.downcase
      params[:customer_phone] = user.mobile_number
    end

    params
  end

  def populate_show_supporting_state
    @recent_enquiries = @property.enquiries.recent_first.limit(3)
    @recent_offers = @property.offers.recent_first.limit(3)
    @recent_rental_applications = @property.rental_applications.recent_first.limit(3)
    @public_documents = @property.public_documents
    @recent_activity = @property.activity_timeline(limit: 8)
    @saved_property = current_user&.saved_properties&.find_by(property: @property)
  end

  def preselected_slot
    return if params[:slot].blank?

    Time.zone.parse(params[:slot])
  rescue ArgumentError, TypeError
    nil
  end

  def booking_form_defaults
    return {} unless current_user.present?

    {
      customer_name: current_user.full_name,
      customer_email: current_user.email,
      customer_phone: current_user.mobile_number
    }
  end

end
