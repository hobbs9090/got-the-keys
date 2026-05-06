class AppointmentsController < ApplicationController
  BOOKING_FORM_SLOT_LIMIT = 1000

  before_action :set_property, only: %i[new create]
  before_action :require_authenticated_user_for_booking!, only: %i[new create]
  before_action :prevent_owner_booking!, only: %i[new create]
  before_action :set_appointment, only: %i[show edit_self_service reschedule_self_service cancel_self_service]
  before_action :authorize_public_access!, only: %i[show edit_self_service reschedule_self_service cancel_self_service]
  before_action :authorize_customer_self_service!, only: %i[edit_self_service]
  before_action :guard_customer_self_service_mutation!, only: %i[reschedule_self_service cancel_self_service]

  def new
    redirect_to property_path(@property, slot: params[:slot], anchor: "booking-panel")
  end

  def create
    @appointment = @property.appointments.new(appointment_params)
    @appointment.status = "pending"
    @appointment.scheduled_at = @appointment.requested_time

    if @appointment.save
      save_property_for_current_user!
      redirect_to appointment_path(@appointment, token: @appointment.access_token), notice: t("ui.appointments.new.submitted_notice")
    else
      @available_slots = @property.next_available_slots(limit: BOOKING_FORM_SLOT_LIMIT)
      @recent_enquiries = @property.enquiries.recent_first.limit(3)
      @recent_offers = @property.offers.recent_first.limit(3)
      @recent_rental_applications = @property.rental_applications.recent_first.limit(3)
      @public_documents = @property.public_documents
      @recent_activity = @property.activity_timeline(limit: 8)
      @saved_property = current_user&.saved_properties&.find_by(property: @property)
      render "properties/show", status: :unprocessable_entity
    end
  end

  def show
  end

  def edit_self_service
    @available_slots = @appointment.property.next_available_slots(limit: BOOKING_FORM_SLOT_LIMIT, excluding_appointment: @appointment)
  end

  def reschedule_self_service
    requested_time = parse_requested_time

    if requested_time.blank?
      @available_slots = @appointment.property.next_available_slots(limit: BOOKING_FORM_SLOT_LIMIT, excluding_appointment: @appointment)
      @appointment.errors.add(:requested_time, t("ui.appointments.self_service.choose_slot"))
      render :edit_self_service, status: :unprocessable_entity
      return
    end

    if @appointment.update(requested_time:, scheduled_at: requested_time, status: "rescheduled")
      redirect_to appointment_path(@appointment, token: @appointment.access_token), notice: t("ui.appointments.self_service.flash.rescheduled")
    else
      @available_slots = @appointment.property.next_available_slots(limit: BOOKING_FORM_SLOT_LIMIT, excluding_appointment: @appointment)
      render :edit_self_service, status: :unprocessable_entity
    end
  end

  def cancel_self_service
    if @appointment.update(status: "cancelled")
      redirect_to appointment_path(@appointment, token: @appointment.access_token), notice: t("ui.appointments.self_service.flash.cancelled")
    else
      redirect_to appointment_path(@appointment, token: @appointment.access_token), alert: @appointment.errors.full_messages.to_sentence
    end
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_appointment
    @appointment = Appointment.includes(:property, :appointment_events).find_by!(public_reference: params[:public_reference] || params[:id])
  end

  def appointment_params
    permitted = params.require(:appointment).permit(:customer_name, :customer_email, :customer_phone, :requested_time, :notes)
    return permitted unless current_user.present?

    permitted.merge(customer_email: current_user.email)
  end

  def authorize_public_access!
    return if current_admin.present?
    return if @appointment.valid_access_token?(params[:token].to_s)

    redirect_to root_path, alert: t("ui.appointments.show.invalid_link_alert")
  end

  def authorize_customer_self_service!
    return if current_admin.present?
    return if @appointment.manageable_by_customer?

    redirect_to appointment_path(@appointment, token: @appointment.access_token), alert: t("ui.appointments.self_service.flash.expired")
  end

  def guard_customer_self_service_mutation!
    authorize_customer_self_service!
  end

  def preselected_slot
    return if params[:slot].blank?

    Time.zone.parse(params[:slot])
  rescue ArgumentError, TypeError
    nil
  end

  def parse_requested_time
    Time.zone.parse(params.require(:appointment).fetch(:requested_time))
  rescue ActionController::ParameterMissing, ArgumentError, TypeError
    nil
  end

  def require_authenticated_user_for_booking!
    return if user_signed_in?

    redirect_to new_user_session_path(return_to: property_path(@property, anchor: "booking-panel"))
  end

  def save_property_for_current_user!
    return unless current_user.present?

    current_user.saved_properties.find_or_create_by!(property: @property)
  end

  def prevent_owner_booking!
    return unless @property.user == current_user

    redirect_to property_path(@property, anchor: "booking-panel"), alert: t("ui.appointments.new.owner_alert")
  end

end
