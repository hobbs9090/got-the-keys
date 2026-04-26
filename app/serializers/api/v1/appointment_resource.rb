module Api
  module V1
    class AppointmentResource
      class << self
        def render(appointment, current_user: nil, host:)
          {
            public_reference:  appointment.public_reference,
            property:          property_summary(appointment.property, current_user: current_user, host: host),
            scheduled_at:      appointment.scheduled_at&.utc&.iso8601,
            ends_at:           appointment.end_at&.utc&.iso8601,
            duration_minutes:  appointment.duration_minutes,
            status:            appointment.status,
            visit_outcome:     appointment.visit_outcome,
            notes:             appointment.notes,
            self_service:      {
              can_reschedule: appointment.manageable_by_customer?,
              can_cancel:     appointment.manageable_by_customer?,
              expires_at:     appointment.self_service_expires_at&.utc&.iso8601
            },
            created_at:        appointment.created_at&.utc&.iso8601,
            updated_at:        appointment.updated_at&.utc&.iso8601
          }
        end

        private

        def property_summary(property, current_user:, host:)
          return nil if property.nil?

          PropertySummaryResource.render(property,
                                          current_user: current_user,
                                          host: host,
                                          next_slot: nil)
        end
      end
    end
  end
end
