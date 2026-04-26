module Api
  module V1
    module Auth
      # Rotating refresh-token flow. See docs/api/v1-spec.md §4.4.
      #
      # Reuse of an already-revoked refresh token is treated as a critical
      # signal: we revoke every refresh token for that user.
      class RefreshesController < BaseController
        # POST /api/v1/auth/refresh
        def create
          presented = params[:refresh_token].to_s
          if presented.blank?
            return render_unauthenticated(
              code:    "refresh_invalid",
              message: I18n.t("api.errors.refresh_required", default: "refresh_token is required.")
            )
          end

          token = ApiRefreshToken.find_by_presented(presented)

          if token.nil?
            handle_potential_reuse(presented)
            return render_unauthenticated(
              code:    "refresh_invalid",
              message: I18n.t("api.errors.refresh_invalid", default: "Refresh token is invalid or has expired.")
            )
          end

          ActiveRecord::Base.transaction do
            token.revoke!(reason: "rotation")

            # Rotate: issue a new refresh token tied to the same device, plus a
            # new JWT. The user's JTI is *not* rotated here — only logout does
            # that.
            _new_record, refresh_plain = ApiRefreshToken.issue!(
              user:        token.user,
              device_id:   token.device_id,
              device_name: token.device_name,
              user_agent:  request.user_agent,
              ip_address:  request.remote_ip
            )
            access_token, _payload = JwtTokenIssuer.issue(token.user)

            render json: {
              access_token:  access_token,
              refresh_token: refresh_plain,
              token_type:    "Bearer",
              expires_in:    JwtTokenIssuer.expires_in
            }, status: :ok
          end
        end

        private

        # If the presented token *was* a real one but is already revoked or
        # expired, that's reuse — burn down all of this user's refresh tokens
        # and rotate their JTI to force a re-login on every device.
        def handle_potential_reuse(presented)
          return unless presented.start_with?("rt_")

          id_segment = presented.split(/[._]/, 3)[1]
          record = id_segment && ApiRefreshToken.unscoped.find_by(id: id_segment)
          return unless record
          return unless ActiveSupport::SecurityUtils.secure_compare(
            record.token_digest,
            ApiRefreshToken.digest_for(presented.split(/[._]/, 3)[2].to_s)
          )

          # Looks like a genuine but-revoked-or-expired token. Treat as compromise.
          ApiRefreshToken.where(user_id: record.user_id).active.find_each do |t|
            t.revoke!(reason: "reuse_detected")
          end
          record.user&.rotate_jwt_jti!
          Rails.logger.warn("[api_refresh_token] reuse detected for user_id=#{record.user_id}")
        rescue StandardError => e
          Rails.logger.error("[api_refresh_token] reuse-check failed: #{e.class}: #{e.message}")
        end
      end
    end
  end
end
