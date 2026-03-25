class AppointmentsController < ApplicationController
  before_action :set_property, only: %i[new create]
  before_action :set_appointment, only: :show

  def new
    @appointment = @property.appointments.new(
      requested_time: preselected_slot,
      scheduled_at: preselected_slot,
      duration_minutes: booking_configuration.slot_duration_minutes
    )
    @available_slots = @property.next_available_slots(limit: 10)
  end

  def create
    @appointment = @property.appointments.new(appointment_params)
    @appointment.status = "pending"
    @appointment.scheduled_at = @appointment.requested_time

    if @appointment.save
      redirect_to appointment_path(@appointment, token: @appointment.access_token), notice: "Appointment request submitted. We will email you with updates."
    else
      @available_slots = @property.next_available_slots(limit: 10)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    token = params[:token].to_s

    return if current_admin.present?
    return if token.present? && token.bytesize == @appointment.access_token.to_s.bytesize && ActiveSupport::SecurityUtils.secure_compare(token, @appointment.access_token.to_s)

    redirect_to root_path, alert: "That appointment link is not valid."
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

  def preselected_slot
    return if params[:slot].blank?

    Time.zone.parse(params[:slot])
  rescue ArgumentError, TypeError
    nil
  end
end
