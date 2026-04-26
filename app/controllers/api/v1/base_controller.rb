module Api
  module V1
    # Foundation for every controller in /api/v1. Pure JSON, no view rendering,
    # no CSRF, no flash. Subclass and `skip_before_action :authenticate_api_user!`
    # for public endpoints.
    class BaseController < ActionController::API
      include Api::V1::ErrorHandling
      include Api::V1::Localized
      include Api::V1::JwtAuthenticatable
      include Api::V1::Paginated

      before_action :set_default_response_format
      before_action :set_request_id_header
      before_action :set_no_store_for_authenticated

      private

      def set_default_response_format
        request.format = :json
      end

      def set_request_id_header
        response.set_header("X-Request-Id", request.request_id) if request.request_id.present?
      end

      # Don't let proxies cache responses for authenticated users by default.
      # Public read endpoints opt back in to caching with explicit Cache-Control.
      def set_no_store_for_authenticated
        return unless current_user

        response.set_header("Cache-Control", "private, no-store")
      end

      def render_resource(resource, status: :ok, **opts)
        render json: resource, status: status, **opts
      end

      def render_collection(collection_serializer:, scope:, status: :ok)
        paged = paginate(scope)
        render json: {
          data:  collection_serializer.call(paged, current_user: current_user),
          meta:  pagination_meta(paged),
          links: pagination_links(paged)
        }, status: status
      end
    end
  end
end
