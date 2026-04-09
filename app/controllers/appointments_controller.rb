class AppointmentsController < ApplicationController
  before_action :set_property, only: %i[new create]
  before_action :set_appointment, only: %i[show edit_self_service reschedule_self_service cancel_self_service]
  before_action :authorize_public_access!, only: %i[show edit_self_service reschedule_self_service cancel_self_service]
  before_action :authorize_customer_self_service!, only: %i[edit_self_service reschedule_self_service cancel_self_service]

  def new
    @appointment = @property.appointments.new(
      default_appointment_attributes.merge(
        requested_time: preselected_slot,
        scheduled_at: preselected_slot,
        duration_minutes: booking_configuration.slot_duration_minutes
      )
    )
    @available_slots = @property.next_available_slots(limit: 10)
  end

  def create
    @appointment = @property.appointments.new(appointment_params)
    @appointment.status = "pending"
    @appointment.scheduled_at = @appointment.requested_time

    if @appointment.save
      redirect_to appointment_path(@appointment, token: @appointment.access_token), notice: t("ui.appointments.new.submitted_notice")
    else
      @available_slots = @property.next_available_slots(limit: 10)
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit_self_service
    @available_slots = @appointment.property.next_available_slots(limit: 10, excluding_appointment: @appointment)
  end

  def reschedule_self_service
    requested_time = parse_requested_time

    if requested_time.blank?
      @available_slots = @appointment.property.next_available_slots(limit: 10, excluding_appointment: @appointment)
      @appointment.errors.add(:requested_time, t("ui.appointments.self_service.choose_slot"))
      render :edit_self_service, status: :unprocessable_entity
      return
    end

    if @appointment.update(requested_time:, scheduled_at: requested_time, status: "rescheduled")
      redirect_to appointment_path(@appointment, token: @appointment.access_token), notice: t("ui.appointments.self_service.flash.rescheduled")
    else
      @available_slots = @appointment.property.next_available_slots(limit: 10, excluding_appointment: @appointment)
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
    params.require(:appointment).permit(:customer_name, :customer_email, :customer_phone, :requested_time, :notes)
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

  def default_appointment_attributes
    return {} unless current_user.present?

    {
      customer_name: current_user.full_name,
      customer_email: current_user.email,
      customer_phone: current_user.mobile_number
    }
  end
end
