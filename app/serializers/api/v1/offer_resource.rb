module Api
  module V1
    class OfferResource
      class << self
        def render(offer, current_user: nil, host:)
          {
            public_reference:   offer.public_reference,
            property:           property_summary(offer.property, current_user: current_user, host: host),
            amount_pence:       offer.amount.to_i,
            amount_display:     "£#{ActiveSupport::NumberHelper.number_to_delimited(offer.amount.to_i / 100)}",
            chain_position:     offer.chain_position,
            status:             offer.status,
            decision_made_at:   offer.decision_made_at&.utc&.iso8601,
            notes:              offer.notes,
            withdrawable:       offer.withdrawable?,
            created_at:         offer.created_at&.utc&.iso8601,
            timeline:           offer.timeline.map { |e| event_payload(e) }
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
