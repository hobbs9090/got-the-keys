module Api
  module V1
    module Auth
      # Auth endpoints don't need to be authenticated themselves — registering,
      # logging in, refreshing, and password reset all happen prior to having a
      # JWT in hand. Logout is the exception (handled inside SessionsController).
      class BaseController < Api::V1::BaseController
        skip_before_action :authenticate_api_user!, raise: false

        protected

        def device_attrs
          {
            device_id:   params[:device_id].to_s.strip.presence,
            device_name: params[:device_name].to_s.strip.presence,
            user_agent:  request.user_agent,
            ip_address:  request.remote_ip
          }
        end

        def require_device_id!
          return true if params[:device_id].to_s.strip.present?

          render_error(
            status: :bad_request,
            code:   "bad_request",
            message: I18n.t("api.errors.device_id_required",
                            default: "device_id is required."),
            details: [{ field: "device_id", code: "blank", message: "is required" }]
          )
          false
        end

        # Issues a fresh access + refresh token pair and renders the standard
        # auth response envelope.
        def render_auth_response(user, audience: "ios", status: :ok)
          access_token, _payload = JwtTokenIssuer.issue(user, audience: audience)
          _record, refresh_plain = ApiRefreshToken.issue!(
            user:        user,
            device_id:   device_attrs[:device_id],
            device_name: device_attrs[:device_name],
            user_agent:  device_attrs[:user_agent],
            ip_address:  device_attrs[:ip_address]
          )

          render json: {
            user:          UserResource.render(user),
            access_token:  access_token,
            refresh_token: refresh_plain,
            token_type:    "Bearer",
            expires_in:    JwtTokenIssuer.expires_in
          }, status: status
        end
      end
    end
  end
end
