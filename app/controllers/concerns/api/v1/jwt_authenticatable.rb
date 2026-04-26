module Api
  module V1
    # Authenticates JSON API requests using JWT bearer tokens.
    #
    # Tokens are encoded with the User scope by Api::V1::Auth::SessionsController
    # via JwtTokenIssuer. devise-jwt's Warden strategy decodes them and verifies
    # the JTI against the User#jti via JTIMatcher.
    #
    # Endpoints that should be public skip the before_action:
    #
    #   skip_before_action :authenticate_api_user!, only: [:index, :show]
    #
    # On unauthenticated requests we return 401 with a "token_expired" code if
    # the JWT decode failed because of expiry — iOS uses that to trigger refresh.
    module JwtAuthenticatable
      extend ActiveSupport::Concern

      included do
        before_action :authenticate_api_user!
        helper_method :current_user, :user_signed_in? if respond_to?(:helper_method)
      end

      def current_user
        @current_api_user
      end

      def user_signed_in?
        current_user.present?
      end

      private

      def authenticate_api_user!
        token = bearer_token
        if token.blank?
          return render_unauthenticated(code: "unauthenticated",
                                        message: I18n.t("api.errors.missing_token", default: "Missing bearer token."))
        end

        decoded = JwtTokenIssuer.decode(token)
        unless decoded
          return render_unauthenticated(code: "token_expired",
                                        message: I18n.t("api.errors.token_invalid", default: "Token is invalid or expired."))
        end

        user = User.find_by(id: decoded["sub"])
        if user.nil? || decoded["jti"].blank? || decoded["jti"] != user.jti
          return render_unauthenticated(code: "token_expired",
                                        message: I18n.t("api.errors.token_revoked", default: "Token has been revoked."))
        end

        @current_api_user = user
      end

      # Some endpoints (e.g. properties#index) are public but enrich the response
      # when an Authorization header is present. Use this from a before_action.
      def authenticate_api_user_optional
        return if request.headers["Authorization"].blank?

        # Don't fail the request — just attempt to load a user and ignore failures.
        token   = bearer_token
        decoded = token && JwtTokenIssuer.decode(token)
        user    = decoded && User.find_by(id: decoded["sub"])
        @current_api_user = user if user && decoded["jti"] == user.jti
      end

      def bearer_token
        header = request.headers["Authorization"].to_s
        return nil if header.blank?

        scheme, token = header.split(" ", 2)
        return nil unless scheme&.casecmp("bearer")&.zero?

        token.to_s.strip.presence
      end

      def require_owner!(record, owner_attr: :user_id)
        owner_id = record.public_send(owner_attr)
        if current_user.nil? || owner_id != current_user.id
          render_forbidden
          throw(:abort)
        end
      end
    end
  end
end
