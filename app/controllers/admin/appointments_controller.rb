class Admin::AppointmentsController < Admin::BaseController
  before_action :set_appointment, only: %i[show edit update transition]
  before_action :load_filters, only: :index

  def index
    @view_mode = params[:view].presence_in(%w[agenda day week month]) || "agenda"
    @anchor_date = parse_date(params[:date]) || Date.current
    scope = Appointment.includes(:property, :admin).recent_first
    scope = scope.where(property_id: params[:property_id]) if params[:property_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(admin_id: params[:admin_id]) if params[:admin_id].present?
    scope = scope.where("lower(customer_email) = ?", params[:customer_email].to_s.downcase) if params[:customer_email].present?
    scope = scope.where(scheduled_at: appointment_range) if appointment_range.present?

    @appointments = scope.order(:scheduled_at, :created_at)
    @appointments_by_day = @appointments.group_by { |appointment| appointment.scheduled_at.to_date }
    @calendar_days = calendar_days_for(@view_mode, @anchor_date)
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

  private

  def set_appointment
    @appointment = Appointment.includes(:property, :appointment_events).find_by!(public_reference: params[:id])
  end

  def load_filters
    @properties = Property.order(:address_line_1)
    @admins = Admin.order(:email)
    @statuses = Appointment::STATUSES
  end

  def appointment_params
    params.require(:appointment).permit(:customer_name, :customer_email, :customer_phone, :requested_time, :scheduled_at, :duration_minutes, :status, :notes, :internal_notes)
  end

  def appointment_range
    if params[:from].present? || params[:to].present?
      from = parse_date(params[:from]) || Date.current
      to = parse_date(params[:to]) || from
      from.beginning_of_day..to.end_of_day
    else
      case params[:view]
      when "day"
        @anchor_date.beginning_of_day..@anchor_date.end_of_day
      when "week"
        @anchor_date.beginning_of_week.beginning_of_day..@anchor_date.end_of_week.end_of_day
      when "month"
        @anchor_date.beginning_of_month.beginning_of_week.beginning_of_day..@anchor_date.end_of_month.end_of_week.end_of_day
      else
        Date.current.beginning_of_day..(Date.current + 14.days).end_of_day
      end
    end
  end

  def calendar_days_for(view_mode, anchor_date)
    case view_mode
    when "day"
      [anchor_date]
    when "week"
      (anchor_date.beginning_of_week..anchor_date.end_of_week).to_a
    when "month"
      (anchor_date.beginning_of_month.beginning_of_week..anchor_date.end_of_month.end_of_week).to_a
    else
      []
    end
  end

  def parse_date(value)
    Date.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
