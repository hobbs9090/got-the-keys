module Api
  module V1
    module Auth
      class RegistrationsController < BaseController
        # POST /api/v1/auth/register
        def create
          return unless require_device_id!

          user = User.new(registration_params)
          user.terms_of_service = ActiveModel::Type::Boolean.new.cast(params[:terms_of_service])

          if user.save
            render_auth_response(user, status: :created)
          else
            render_validation_error(user)
          end
        end

        private

        def registration_params
          params.permit(:email, :password, :first_name, :last_name,
                        :mobile_number, :language).to_h
        end
      end
    end
  end
end
