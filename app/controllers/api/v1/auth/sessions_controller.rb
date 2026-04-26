module Api
  module V1
    module Auth
      class SessionsController < BaseController
        # POST /api/v1/auth/login
        def create
          return unless require_device_id!

          email    = params[:email].to_s.strip.downcase.presence
          password = params[:password].to_s

          user = email && User.find_by("lower(email) = ?", email)

          if user.nil?
            return render_unauthenticated(
              code: "unauthenticated",
              message: I18n.t("api.errors.invalid_credentials", default: "Email or password is incorrect.")
            )
          end

          if user.respond_to?(:access_locked?) && user.access_locked?
            return render_locked(
              message: I18n.t("api.errors.account_locked", default: "Your account is temporarily locked. Try again later.")
            )
          end

          unless user.valid_password?(password)
            user.increment_failed_attempts if user.respond_to?(:increment_failed_attempts)
            user.lock_access! if user.respond_to?(:attempts_exceeded?) && user.attempts_exceeded?
            return render_unauthenticated(
              code: "unauthenticated",
              message: I18n.t("api.errors.invalid_credentials", default: "Email or password is incorrect.")
            )
          end

          # Mirror Devise's trackable + reset failed attempts on success.
          user.reset_failed_attempts! if user.respond_to?(:reset_failed_attempts!)
          user.update_columns(
            sign_in_count:        user.sign_in_count.to_i + 1,
            last_sign_in_at:      user.current_sign_in_at,
            last_sign_in_ip:      user.current_sign_in_ip,
            current_sign_in_at:   Time.current,
            current_sign_in_ip:   request.remote_ip,
            updated_at:           Time.current
          )

          render_auth_response(user)
        end

        # DELETE /api/v1/auth/logout
        # Revokes the supplied refresh token and rotates the user's JTI so all
        # outstanding access tokens become invalid. See docs/api/v1-spec.md §4.4.
        def destroy
          # Logout requires authentication so we can identify the user.
          authenticate_api_user!
          return if performed?

          presented = params[:refresh_token].to_s
          if presented.present?
            token = ApiRefreshToken.find_by_presented(presented)
            token&.revoke!(reason: "logout") if token && token.user_id == current_user.id
          end

          # Invalidate every outstanding access token for this user.
          current_user.rotate_jwt_jti!

          render json: { logged_out: true }, status: :ok
        end
      end
    end
  end
end
