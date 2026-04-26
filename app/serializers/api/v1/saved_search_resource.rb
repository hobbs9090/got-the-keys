module Api
  module V1
    class SavedSearchResource
      class << self
        def render(saved_search)
          {
            id:               saved_search.id,
            search_query:     saved_search.search_query,
            sale_status:      api_sale_status(saved_search.sale_status),
            town_city:        saved_search.town_city,
            min_bedrooms:     saved_search.min_bedrooms,
            min_price_pence:  saved_search.min_price,
            max_price_pence:  saved_search.max_price,
            sort:             api_sort(saved_search.sort),
            alerts_enabled:   saved_search.alerts_enabled,
            matching_count:   saved_search.matching_properties_count,
            created_at:       saved_search.created_at&.utc&.iso8601,
            updated_at:       saved_search.updated_at&.utc&.iso8601
          }
        end

        private

        def api_sale_status(value)
          case value
          when Property::SALE_STATUSES[:for_sale] then "for_sale"
          when Property::SALE_STATUSES[:for_rent] then "for_rent"
          else nil
          end
        end

        def api_sort(value)
          case value
          when "price_low"  then "price_asc"
          when "price_high" then "price_desc"
          else value
          end
        end
      end
    end
  end
end
