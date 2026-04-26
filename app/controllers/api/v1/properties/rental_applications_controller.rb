module Api
  module V1
    module Properties
      class RentalApplicationsController < BaseController
        # POST /api/v1/properties/:property_id/rental_applications
        def create
          property = Property.publicly_visible.find_by(id: params[:property_id])
          return render_not_found if property.nil?

          unless property.sale_status == Property::SALE_STATUSES[:for_rent]
            return render_error(
              status: :unprocessable_entity, code: "validation_failed",
              message: I18n.t("api.errors.application_requires_rental_listing",
                               default: "Rental applications can only be made on letting listings."),
              details: [{ field: "property_id", code: "invalid", message: "must be a rental listing" }]
            )
          end

          if property.user_id == current_user.id
            return render_error(
              status: :unprocessable_entity, code: "validation_failed",
              message: I18n.t("api.errors.cannot_apply_own_property",
                               default: "You cannot apply to rent your own listing."),
              details: [{ field: "property_id", code: "invalid", message: "cannot apply to own listing" }]
            )
          end

          application = property.rental_applications.build(
            applicant_name:      current_user.full_name.presence || current_user.email,
            applicant_email:     current_user.email,
            applicant_phone:     current_user.mobile_number.presence || "0000000000",
            move_in_date:        parse_move_in_date(params[:move_in_date]),
            guarantor_available: ActiveModel::Type::Boolean.new.cast(params.fetch(:guarantor_available, false)),
            guarantor_required:  ActiveModel::Type::Boolean.new.cast(params.fetch(:guarantor_required, false)),
            affordability_notes: params[:affordability_notes].to_s.strip.presence,
            notes:               params[:notes].to_s.strip.presence
          )

          if application.save
            render json: RentalApplicationResource.render(application,
                                                           current_user: current_user,
                                                           host: api_host),
                   status: :created
          else
            render_validation_error(application)
          end
        end

        private

        def parse_move_in_date(raw)
          return nil if raw.blank?

          Date.iso8601(raw.to_s)
        rescue ArgumentError, TypeError
          nil
        end

        def api_host
          "#{request.protocol}#{request.host_with_port}"
        end
      end
    end
  end
end
