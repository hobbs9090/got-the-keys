module Api
  module V1
    class EnquiryResource
      class << self
        def render(enquiry, current_user: nil, host:)
          {
            lead_reference:   enquiry.lead_reference,
            property:         property_summary(enquiry.property, current_user: current_user, host: host),
            message:          enquiry.message,
            source_type:      enquiry.source_type,
            status:           enquiry.status,
            contacted_at:     enquiry.contacted_at&.utc&.iso8601,
            created_at:       enquiry.created_at&.utc&.iso8601
          }
        end

        private

        def property_summary(property, current_user:, host:)
          return nil if property.nil?

          PropertySummaryResource.render(property, current_user: current_user, host: host, next_slot: nil)
        end
      end
    end
  end
end
