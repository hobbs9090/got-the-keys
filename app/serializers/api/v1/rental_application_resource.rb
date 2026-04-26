module Api
  module V1
    class RentalApplicationResource
      class << self
        def render(application, current_user: nil, host:)
          {
            public_reference:    application.public_reference,
            property:            property_summary(application.property, current_user: current_user, host: host),
            move_in_date:        application.move_in_date&.iso8601,
            guarantor_available: application.guarantor_available,
            guarantor_required:  application.guarantor_required,
            affordability_notes: application.affordability_notes,
            status:              application.status,
            decision_made_at:    application.decision_made_at&.utc&.iso8601,
            notes:               application.notes,
            withdrawable:        application.withdrawable?,
            created_at:          application.created_at&.utc&.iso8601,
            timeline:            application.timeline.map { |e| event_payload(e) }
          }
        end

        private

        def property_summary(property, current_user:, host:)
          return nil if property.nil?

          PropertySummaryResource.render(property, current_user: current_user, host: host, next_slot: nil)
        end

        def event_payload(event)
          {
            event_type:  event.event_type,
            from_status: event.from_status,
            to_status:   event.to_status,
            message:     event.message,
            occurred_at: event.occurred_at&.utc&.iso8601
          }
        end
      end
    end
  end
end
