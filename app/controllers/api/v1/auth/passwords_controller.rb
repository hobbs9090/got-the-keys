module Api
  module V1
    module Auth
      class PasswordsController < BaseController
        # POST /api/v1/auth/password
        # Always returns 202 to avoid user enumeration. The actual email is
        # only sent when the email matches a registered user (Devise handles
        # this internally via send_reset_password_instructions).
        def create
          email = params[:email].to_s.strip.downcase.presence
          if email.present?
            user = User.find_by("lower(email) = ?", email)
            user&.send_reset_password_instructions
          end

          render json: {
            accepted: true,
            message: I18n.t("api.messages.password_reset_sent",
                            default: "If that email is registered, password reset instructions have been sent.")
          }, status: :accepted
        end

        # PATCH /api/v1/auth/password
        def update
          token = params[:reset_password_token].to_s
          if token.blank?
            return render_error(status: :bad_request, code: "bad_request",
                                message: "reset_password_token is required.",
                                details: [{ field: "reset_password_token", code: "blank", message: "is required" }])
          end

          attrs = {
            reset_password_token: token,
            password:              params[:password].to_s,
            password_confirmation: params[:password_confirmation].to_s.presence || params[:password].to_s
          }

          user = User.reset_password_by_token(attrs)
          if user.errors.empty? && user.persisted?
            user.unlock_access! if user.respond_to?(:unlock_access!) && user.access_locked?
            render json: {
              user: UserResource.render(user),
              message: I18n.t("api.messages.password_updated", default: "Password has been updated.")
            }, status: :ok
          else
            render_validation_error(user)
          end
        end
      end
    end
  end
end
