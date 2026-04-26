module Api
  module V1
    class AppointmentsController < BaseController
      before_action :load_appointment, only: %i[show reschedule cancel]

      # GET /api/v1/appointments
      def index
        scope = current_user_appointments_scope
        scope = filter_by_status(scope) if params[:status].present?
        scope = scope.includes(:property)

        render_collection(
          collection_serializer: method(:serialize_collection),
          scope: scope.recent_first
        )
      end

      # GET /api/v1/appointments/:public_reference
      def show
        render json: AppointmentResource.render(@appointment,
                                                  current_user: current_user,
                                                  host: api_host)
      end

      # PATCH /api/v1/appointments/:public_reference/reschedule
      def reschedule
        unless @appointment.manageable_by_customer?
          return render_error(
            status: :conflict, code: "conflict",
            message: I18n.t("api.errors.appointment_self_service_expired",
                             default: "This appointment can no longer be managed from the app.")
          )
        end

        new_time = parse_time(params[:scheduled_at])
        if new_time.nil?
          return render_error(
            status: :unprocessable_entity, code: "validation_failed",
            message: I18n.t("api.errors.scheduled_at_required",
                             default: "A new appointment time is required."),
            details: [{ field: "scheduled_at", code: "blank", message: "must be a valid ISO 8601 datetime" }]
          )
        end

        if @appointment.update(requested_time: new_time, scheduled_at: new_time, status: "rescheduled")
          render json: AppointmentResource.render(@appointment,
                                                    current_user: current_user,
                                                    host: api_host)
        else
          render_validation_error(@appointment)
        end
      end

      # PATCH /api/v1/appointments/:public_reference/cancel
      def cancel
        unless @appointment.manageable_by_customer?
          return render_error(
            status: :conflict, code: "conflict",
            message: I18n.t("api.errors.appointment_self_service_expired",
                             default: "This appointment can no longer be managed from the app.")
          )
        end

        # Cancellation skips slot validation — the appointment is leaving the
        # active set, so AppointmentAvailability shouldn't block it.
        @appointment.skip_slot_validation = true
        reason = params[:reason].to_s.strip
        if reason.present?
          @appointment.notes = [@appointment.notes.to_s, reason].reject(&:blank?).join("\n\n")
        end
        if @appointment.update(status: "cancelled")
          render json: AppointmentResource.render(@appointment,
                                                    current_user: current_user,
                                                    host: api_host)
        else
          render_validation_error(@appointment)
        end
      end

      private

      def current_user_appointments_scope
        Appointment.where("lower(customer_email) = ?", current_user.email.to_s.downcase)
      end

      def filter_by_status(scope)
        statuses = Array(params[:status]).map(&:to_s) & Appointment::STATUSES
        return scope if statuses.empty?

        scope.where(status: statuses)
      end

      def load_appointment
        @appointment = current_user_appointments_scope
                         .includes(:property, :appointment_events)
                         .find_by(public_reference: params[:public_reference])
        render_not_found if @appointment.nil?
      end

      def serialize_collection(records, current_user:)
        host = api_host
        records.map { |a| AppointmentResource.render(a, current_user: current_user, host: host) }
      end

      def parse_time(raw)
        return nil if raw.blank?

        Time.zone.parse(raw.to_s)
      rescue ArgumentError, TypeError
        nil
      end

      def api_host
        "#{request.protocol}#{request.host_with_port}"
      end
    end
  end
end
