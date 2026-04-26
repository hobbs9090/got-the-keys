module Api
  module V1
    module Properties
      class AppointmentsController < BaseController
        # POST /api/v1/properties/:property_id/appointments
        def create
          property = Property.publicly_visible.find_by(id: params[:property_id])
          return render_not_found if property.nil?

          if property.user_id == current_user.id
            return render_error(
              status: :unprocessable_entity, code: "validation_failed",
              message: I18n.t("api.errors.cannot_book_own_property",
                               default: "You cannot book a viewing on your own listing."),
              details: [{ field: "property_id", code: "invalid", message: "cannot book own listing" }]
            )
          end

          scheduled_at = parse_time(params[:scheduled_at])
          duration     = (params[:duration_minutes].presence || BookingConfiguration.current.slot_duration_minutes).to_i

          appointment = property.appointments.build(
            customer_name:    current_user.full_name.presence || current_user.email,
            customer_email:   current_user.email,
            customer_phone:   current_user.mobile_number.presence || "0000000000",
            requested_time:   scheduled_at,
            scheduled_at:     scheduled_at,
            duration_minutes: duration,
            notes:            params[:notes].to_s.strip.presence
          )

          if appointment.save
            render json: AppointmentResource.render(appointment,
                                                     current_user: current_user,
                                                     host: api_host),
                   status: :created
          else
            render_validation_error(appointment)
          end
        end

        private

        def parse_time(raw)
          return nil if raw.blank?

          Time.zone.parse(raw.to_s)
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
