module Api
  module V1
    class MeController < BaseController
      # GET /api/v1/me
      def show
        render json: { user: UserResource.render(current_user) }
      end

      # PATCH /api/v1/me
      def update
        if current_user.update(profile_params)
          render json: { user: UserResource.render(current_user) }
        else
          render_validation_error(current_user)
        end
      end

      # DELETE /api/v1/me
      # Soft-delete: anonymize PII and revoke all refresh tokens. Properties,
      # appointments, offers, applications stay (for admin/seller continuity)
      # but with the user record anonymized.
      def destroy
        ActiveRecord::Base.transaction do
          anonymized_email = "deleted-#{current_user.id}@deleted.gotthekeys.invalid"
          current_user.update_columns(
            email:          anonymized_email,
            first_name:     "Deleted",
            last_name:      "User",
            mobile_number:  nil,
            updated_at:     Time.current
          )
          current_user.api_refresh_tokens.active.find_each(&:revoke!)
          current_user.rotate_jwt_jti!
        end

        render json: { deleted: true }, status: :ok
      end

      private

      def profile_params
        params.permit(:first_name, :last_name, :mobile_number, :language)
      end
    end
  end
end
