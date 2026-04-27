module Api
  module V1
    # Compact property representation, used in listing endpoints. See
    # docs/api/v1-spec.md §5.2.
    class PropertySummaryResource
      class << self
        def render(property, current_user: nil, host:, next_slot: :unset)
          {
            id:                  property.id,
            listing_state:       property.listing_state,
            sale_status:         property.sale_status,
            property_type:       property.property_type,
            tagline:             property.listing_tagline.presence || property.headline,
            address:             address_for(property),
            bedrooms:            property.bedrooms,
            bathrooms:           property.bathrooms,
            asking_price_pence:  property.asking_price.to_i,
            asking_price_display: format_money(property.asking_price.to_i),
            currency:            "GBP",
            featured:            property.featured?,
            primary_photo:       primary_photo_for(property, host: host),
            saved_by_me:         saved_by_me_value(property, current_user),
            next_available_slot: format_slot(next_slot),
            url:                 "#{host}/properties/#{property.id}"
          }
        end

        # Renders a collection efficiently. Optionally precomputes the per-property
        # next-available slot via PropertyNextAvailableSlotLookup.
        def render_collection(properties, current_user:, host:, include_next_slots: true)
          slots = if include_next_slots && properties.present?
                    PropertyNextAvailableSlotLookup.new(properties: properties).call(limit: 1)
                  else
                    {}
                  end

          properties.map do |property|
            render(property,
                   current_user: current_user,
                   host: host,
                   next_slot: include_next_slots ? slots[property.id] : nil)
          end
        end

        private

        def address_for(property)
          {
            line_1:    property.address_line_1,
            line_2:    property.address_line_2.presence,
            town_city: property.town_city,
            county:    property.county,
            postcode:  property.postcode,
            country:   property.country
          }
        end

        def primary_photo_for(property, host:)
          photo = property.primary_photo
          return nil if photo.nil?

          PhotoResource.render(photo, host: host)
        end

        def saved_by_me_value(property, current_user)
          return nil if current_user.nil?

          # Avoid N+1: SavedProperty.exists? per row is fine since the index is
          # composite (user_id, property_id) and unique. For listing endpoints
          # we accept the cost as the page size is capped at 50.
          SavedProperty.where(user_id: current_user.id, property_id: property.id).exists?
        end

        def format_slot(slot)
          return nil if slot == :unset || slot.nil?

          starts_at = slot.respond_to?(:starts_at) ? slot.starts_at : slot
          starts_at&.utc&.iso8601
        end

        def format_money(amount)
          "£#{ActiveSupport::NumberHelper.number_to_delimited(amount.to_i)}"
        end
      end
    end
  end
end
