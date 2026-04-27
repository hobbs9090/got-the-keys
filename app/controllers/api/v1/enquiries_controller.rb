module Api
  module V1
    class EnquiriesController < BaseController
      # GET /api/v1/enquiries
      def index
        scope = current_user_enquiries_scope
        scope = scope.for_status(params[:status]) if params[:status].present?
        scope = scope.includes(:property)

        render_collection(
          collection_serializer: method(:serialize_collection),
          scope: scope.recent_first
        )
      end

      private

      def current_user_enquiries_scope
        Enquiry.where("lower(customer_email) = ?", current_user.email.to_s.downcase)
      end

      def serialize_collection(records, current_user:)
        host = "#{request.protocol}#{request.host_with_port}"
        records.map { |e| EnquiryResource.render(e, current_user: current_user, host: host) }
      end
    end
  end
end
