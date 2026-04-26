module Api
  module V1
    # Standard JSON error envelope. Every controller in /api/v1 inherits this.
    # See docs/api/v1-spec.md §7 for the wire format.
    module ErrorHandling
      extend ActiveSupport::Concern

      included do
        rescue_from StandardError,                                with: :render_internal_error
        rescue_from ActionController::ParameterMissing,           with: :render_bad_request
        rescue_from ActionController::UnpermittedParameters,      with: :render_bad_request
        rescue_from ActiveRecord::RecordNotFound,                 with: :render_not_found
        rescue_from ActiveRecord::RecordInvalid,                  with: :render_validation_error
        rescue_from ActiveRecord::RecordNotUnique,                with: :render_conflict
        rescue_from ActionController::RoutingError,               with: :render_not_found
      end

      private

      def render_error(status:, code:, message:, details: nil)
        payload = {
          error: {
            code:       code,
            message:    message,
            request_id: request.request_id
          }
        }
        payload[:error][:details] = details if details.present?
        response.set_header("X-Request-Id", request.request_id) if request.request_id.present?
        render json: payload, status: status
      end

      def render_validation_error(exception_or_record)
        record = exception_or_record.respond_to?(:record) ? exception_or_record.record : exception_or_record
        details = record.errors.map do |error|
          { field: error.attribute.to_s, code: error.type.to_s, message: error.message }
        end
        render_error(
          status:  :unprocessable_entity,
          code:    "validation_failed",
          message: I18n.t("api.errors.validation_failed", default: "Some fields are invalid."),
          details: details
        )
      end

      def render_bad_request(exception = nil)
        render_error(status: :bad_request, code: "bad_request",
                     message: exception&.message.presence ||
                       I18n.t("api.errors.bad_request", default: "Bad request."))
      end

      def render_not_found(_exception = nil)
        render_error(status: :not_found, code: "not_found",
                     message: I18n.t("api.errors.not_found", default: "Resource not found."))
      end

      def render_unauthenticated(code: "unauthenticated", message: nil)
        render_error(
          status:  :unauthorized,
          code:    code,
          message: message || I18n.t("api.errors.unauthenticated", default: "Authentication required.")
        )
      end

      def render_forbidden(message: nil)
        render_error(
          status:  :forbidden,
          code:    "forbidden",
          message: message || I18n.t("api.errors.forbidden", default: "You don't have access to this resource.")
        )
      end

      def render_conflict(exception = nil)
        render_error(
          status:  :conflict,
          code:    "conflict",
          message: exception&.message.presence ||
            I18n.t("api.errors.conflict", default: "The request conflicts with the current state.")
        )
      end

      def render_locked(message: nil)
        render_error(
          status:  :locked,
          code:    "locked",
          message: message || I18n.t("api.errors.locked", default: "Account is temporarily locked.")
        )
      end

      def render_gone(message: nil)
        render_error(
          status:  :gone,
          code:    "gone",
          message: message || I18n.t("api.errors.gone", default: "This resource is no longer available.")
        )
      end

      def render_internal_error(exception)
        Rails.logger.error("[api] 500 #{exception.class}: #{exception.message}\n#{exception.backtrace&.first(20)&.join("\n")}")
        raise exception if Rails.env.development? || Rails.env.test?

        render_error(
          status:  :internal_server_error,
          code:    "internal_error",
          message: I18n.t("api.errors.internal_error", default: "Something went wrong on our side.")
        )
      end
    end
  end
end
