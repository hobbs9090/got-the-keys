class Admin::AppointmentsController < Admin::BaseController
  before_action :set_appointment, only: %i[show edit update transition send_reminder]
  before_action :load_filters, only: :index

  def index
    listing = Admin::AppointmentIndexQuery.new(params:).call

    @view_mode = listing.view_mode
    @anchor_date = listing.anchor_date
    @appointments = listing.appointments
    @appointments_by_day = listing.appointments_by_day
    @calendar_days = listing.calendar_days
  end

  def show
    @customer_history = @appointment.customer_history.limit(10)
  end

  def edit
  end

  def update
    @appointment.assign_attributes(appointment_params.merge(admin: current_admin))

    if @appointment.save
      redirect_to admin_appointment_path(@appointment), notice: t("ui.admin.flash.appointment_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def transition
    new_status = params[:status].presence_in(Appointment::STATUSES)

    unless new_status
      redirect_to admin_appointments_path, alert: t("ui.admin.flash.unsupported_appointment_status")
      return
    end

    if @appointment.update(status: new_status, admin: current_admin)
      redirect_back(
        fallback_location: admin_appointments_path,
        notice: t(
          "ui.admin.flash.appointment_marked",
          status: I18n.t("ui.appointments.statuses.#{new_status}", default: new_status.tr("_", " ").humanize).downcase
        )
      )
    else
      redirect_back fallback_location: admin_appointments_path, alert: @appointment.errors.full_messages.to_sentence
    end
  end

  def send_reminder
    AppointmentNotificationJob.perform_later(@appointment.id, "reminder")
    @appointment.update_column(:reminder_sent_at, Time.current)

    redirect_to admin_appointment_path(@appointment), notice: "Reminder queued."
  end

  private

  def set_appointment
    @appointment = Appointment.includes(:property, :appointment_events).find_by!(public_reference: params[:id])
  end

  def load_filters
    @properties = Property.order(:address_line_1)
    @admins = Admin.order(:email)
    @statuses = Appointment::STATUSES
    @visit_outcomes = Appointment::VISIT_OUTCOMES
  end

  def appointment_params
    params.require(:appointment).permit(:customer_name, :customer_email, :customer_phone, :requested_time, :scheduled_at, :duration_minutes, :status, :visit_outcome, :notes, :internal_notes)
  end
end
