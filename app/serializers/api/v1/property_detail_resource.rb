module Api
  module V1
    class PropertyDetailResource
      class << self
        def render(property, current_user: nil, host:)
          summary = PropertySummaryResource.render(property,
                                                   current_user: current_user,
                                                   host: host,
                                                   next_slot: nil)
          summary.merge(
            description:                 property.property_description,
            tenure:                      property.tenure,
            floor_area_sq_ft:            property.floor_area_sq_ft,
            year_built:                  property.year_built,
            refurbished_year:            property.refurbished_year,
            council_tax_band:            property.council_tax_band,
            pets_allowed:                property.pets_allowed,
            parking:                     property.parking,
            outdoor_space:               property.outdoor_space,
            furnishing:                  property.furnishing,
            deposit_amount_pence:        property.deposit_amount,
            service_charge_amount_pence: property.service_charge_amount,
            lease_length_years:          property.lease_length_years,
            available_from:              property.available_from&.iso8601,
            published_at:                property.published_at&.utc&.iso8601,
            photos:                      property.ordered_photos.map { |p| PhotoResource.render(p, host: host) },
            floor_plans:                 property.ordered_floor_plans.map { |fp| FloorPlanResource.render(fp, host: host) },
            documents:                   property.public_documents.map { |d| DocumentResource.render(d) },
            viewing_times:               property.viewing_times.map do |vt|
              { id: vt.id, start_time: vt.start_time&.utc&.iso8601, end_time: vt.end_time&.utc&.iso8601 }
            end,
            seller:                      seller_for(property)
          ).then { |hash| filter_irrelevant_fields(hash, property) }
        end

        private

        def seller_for(property)
          seller = property.user
          return nil if seller.nil?

          {
            id:        seller.id,
            full_name: seller.full_name,
            first_name: seller.first_name
          }
        end

        # Nil-out rental-only fields on sale listings to keep the contract
        # consistent across listing types. iOS clients always see the same keys.
        def filter_irrelevant_fields(hash, property)
          return hash unless property.sale_status == Property::SALE_STATUSES[:for_sale]

          hash.merge(
            deposit_amount_pence:        nil,
            service_charge_amount_pence: nil,
            lease_length_years:          nil,
            furnishing:                  nil,
            available_from:              nil,
            pets_allowed:                nil
          )
        end
      end
    end
  end
end
