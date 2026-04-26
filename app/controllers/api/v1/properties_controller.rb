module Api
  module V1
    class PropertiesController < BaseController
      # Public endpoints. Authentication is *optional* — when an Authorization
      # header is present, we enrich the response with `saved_by_me`. Otherwise
      # `saved_by_me` is null.
      skip_before_action :authenticate_api_user!
      before_action :authenticate_api_user_optional

      # GET /api/v1/properties
      def index
        scope = Property.filter(filter_params).publicly_visible.preload(:photos, :user)
        paginated = paginate(scope)

        properties = PropertySummaryResource.render_collection(
          paginated,
          current_user: current_user,
          host: api_request_host,
          include_next_slots: true
        )

        set_listing_cache_headers
        render json: {
          data:  properties,
          meta:  pagination_meta(paginated),
          links: pagination_links(paginated)
        }
      end

      # GET /api/v1/properties/:id
      def show
        property = Property.find_by(id: params[:id])

        if property.nil?
          return render_not_found
        end

        unless property.publicly_visible?
          # Distinguish "never visible" from "was visible, now withdrawn".
          if property.listing_state == "withdrawn"
            return render_gone(message: I18n.t("api.errors.property_withdrawn",
                                                default: "This property has been withdrawn."))
          end
          return render_not_found
        end

        set_detail_cache_headers(property)
        render json: PropertyDetailResource.render(property,
                                                   current_user: current_user,
                                                   host: api_request_host)
      end

      # GET /api/v1/properties/:id/availability
      def availability
        property = Property.publicly_visible.find_by(id: params[:id])
        return render_not_found if property.nil?

        from_param = params[:from].presence
        from = (Time.zone.parse(from_param) rescue nil) || Time.current
        days = params[:days].to_i
        days = nil if days <= 0

        availability = AppointmentAvailability.new(property: property, from: from)
        slots = availability.next_slots(limit: params[:limit].to_i.positive? ? params[:limit].to_i : 12,
                                        days_ahead: days)
        config = BookingConfiguration.current

        render json: {
          slots: slots.map do |slot|
            {
              starts_at:     slot.starts_at&.utc&.iso8601,
              ends_at:       slot.ends_at&.utc&.iso8601,
              group_viewing: slot.group_viewing
            }
          end,
          configuration: {
            slot_duration_minutes: config.slot_duration_minutes,
            lead_time_hours:       config.lead_time_hours,
            booking_window_days:   config.booking_window_days
          }
        }
      end

      private

      def filter_params
        permitted = params.permit(:q, :sale_status, :town_city, :min_bedrooms,
                                  :min_price, :max_price, :property_type, :featured, :sort)
        permitted = permitted.to_h.with_indifferent_access
        permitted[:sale_status] = translate_sale_status(permitted[:sale_status]) if permitted[:sale_status].present?
        permitted[:sort]        = translate_sort(permitted[:sort]) if permitted[:sort].present?
        permitted
      end

      # API exposes "for_sale"/"for_rent" enum keys; the model stores
      # "For Sale"/"For Rent" labels. Translate at the boundary.
      def translate_sale_status(value)
        case value.to_s.downcase
        when "for_sale" then Property::SALE_STATUSES[:for_sale]
        when "for_rent" then Property::SALE_STATUSES[:for_rent]
        else value
        end
      end

      def translate_sort(value)
        case value.to_s
        when "price_asc"   then "price_low"
        when "price_desc"  then "price_high"
        when "newest"      then "newest"
        when "recommended" then "recommended"
        else                    value
        end
      end

      def api_request_host
        "#{request.protocol}#{request.host_with_port}"
      end

      def set_listing_cache_headers
        if current_user
          response.set_header("Cache-Control", "private, no-store")
        else
          response.set_header("Cache-Control", "public, max-age=60")
        end
      end

      def set_detail_cache_headers(property)
        if current_user
          response.set_header("Cache-Control", "private, no-store")
        else
          response.set_header("Cache-Control", "public, max-age=60")
          response.set_header("Last-Modified", property.updated_at.httpdate) if property.updated_at
          response.set_header("ETag", property_etag(property))
        end
      end

      def property_etag(property)
        Digest::MD5.hexdigest("property/#{property.id}/#{property.updated_at.to_i}")
      end
    end
  end
end
