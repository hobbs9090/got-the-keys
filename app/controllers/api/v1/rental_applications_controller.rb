module Api
  module V1
    class RentalApplicationsController < BaseController
      before_action :load_application, only: %i[show withdraw]

      # GET /api/v1/rental_applications
      def index
        scope = current_user_applications_scope
        scope = filter_by_status(scope) if params[:status].present?
        scope = scope.includes(:property, :rental_application_events)

        render_collection(
          collection_serializer: method(:serialize_collection),
          scope: scope.recent_first
        )
      end

      # GET /api/v1/rental_applications/:public_reference
      def show
        render json: RentalApplicationResource.render(@application,
                                                       current_user: current_user,
                                                       host: api_host)
      end

      # PATCH /api/v1/rental_applications/:public_reference/withdraw
      def withdraw
        unless @application.withdrawable?
          return render_error(
            status: :conflict, code: "conflict",
            message: I18n.t("api.errors.application_not_withdrawable",
                             default: "This application can no longer be withdrawn.")
          )
        end

        if @application.update(status: "withdrawn")
          render json: RentalApplicationResource.render(@application,
                                                         current_user: current_user,
                                                         host: api_host)
        else
          render_validation_error(@application)
        end
      end

      private

      def current_user_applications_scope
        RentalApplication.where("lower(applicant_email) = ?", current_user.email.to_s.downcase)
      end

      def filter_by_status(scope)
        statuses = Array(params[:status]).map(&:to_s) & RentalApplication::STATUSES
        return scope if statuses.empty?

        scope.where(status: statuses)
      end

      def load_application
        @application = current_user_applications_scope
                         .includes(:property, :rental_application_events)
                         .find_by(public_reference: params[:public_reference])
        render_not_found if @application.nil?
      end

      def serialize_collection(records, current_user:)
        host = api_host
        records.map { |a| RentalApplicationResource.render(a, current_user: current_user, host: host) }
      end

      def api_host
        "#{request.protocol}#{request.host_with_port}"
      end
    end
  end
end
