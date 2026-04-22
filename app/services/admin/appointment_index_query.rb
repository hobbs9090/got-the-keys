class Admin::AppointmentIndexQuery
  VIEW_MODES = %w[agenda day week month].freeze
  Result = Struct.new(:view_mode, :anchor_date, :appointments, :appointments_by_day, :calendar_days, keyword_init: true)

  def initialize(params:, relation: Appointment.all, today: Date.current)
    @params = normalize_params(params)
    @relation = relation
    @today = today
  end

  def call
    view_mode = params[:view].presence_in(VIEW_MODES) || "agenda"
    anchor_date = parse_date(params[:date]) || today
    appointments = filtered_scope(view_mode:, anchor_date:).reorder(:scheduled_at, :created_at, :id)

    Result.new(
      view_mode:,
      anchor_date:,
      appointments:,
      appointments_by_day: appointments.group_by { |appointment| appointment.scheduled_at.to_date },
      calendar_days: calendar_days_for(view_mode:, anchor_date:)
    )
  end

  private

  attr_reader :params, :relation, :today

  def filtered_scope(view_mode:, anchor_date:)
    scope = relation.includes(:property, :admin).recent_first
    scope = scope.where(property_id: params[:property_id]) if params[:property_id].present?
    scope = scope.where(status: %w[pending rescheduled]) if params[:queue] == "pending_action"
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(visit_outcome: params[:visit_outcome]) if params[:visit_outcome].present?
    scope = scope.where(admin_id: params[:admin_id]) if params[:admin_id].present?
    scope = filter_by_customer_email(scope) if params[:customer_email].present?

    range = appointment_range(view_mode:, anchor_date:)
    scope = scope.where(scheduled_at: range) if range.present?
    scope
  end

  def filter_by_customer_email(scope)
    normalized_email = params[:customer_email].to_s.downcase
    matched_user = User.find_by("lower(email) = ?", normalized_email)
    return scope.where("lower(customer_email) = ?", normalized_email) if matched_user.blank?

    scope.where(
      "lower(customer_email) = :email OR (customer_phone = :phone AND lower(customer_name) = :name)",
      email: matched_user.email.downcase,
      phone: matched_user.mobile_number,
      name: matched_user.full_name.downcase
    )
  end

  def appointment_range(view_mode:, anchor_date:)
    if params[:from].present? || params[:to].present?
      from = parse_date(params[:from]) || today
      to = parse_date(params[:to]) || from
      from.beginning_of_day..to.end_of_day
    else
      case view_mode
      when "day"
        anchor_date.beginning_of_day..anchor_date.end_of_day
      when "week"
        anchor_date.beginning_of_week.beginning_of_day..anchor_date.end_of_week.end_of_day
      when "month"
        anchor_date.beginning_of_month.beginning_of_week.beginning_of_day..anchor_date.end_of_month.end_of_week.end_of_day
      else
        today.beginning_of_day..(today + 14.days).end_of_day
      end
    end
  end

  def calendar_days_for(view_mode:, anchor_date:)
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

  def normalize_params(value)
    source =
      if defined?(ActionController::Parameters) && value.is_a?(ActionController::Parameters)
        value.to_unsafe_h
      else
        value.to_h
      end

    source.with_indifferent_access
  end
end
