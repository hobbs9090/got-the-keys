module Api
  module V1
    # Lookup data for the iOS app: enum values, language list, booking window
    # configuration. Aggressively cacheable; ETag derived from
    # BookingConfiguration#updated_at where applicable.
    class ReferenceController < BaseController
      skip_before_action :authenticate_api_user!

      # GET /api/v1/reference/property_types
      def property_types
        set_long_cache_headers
        render json: { data: Property::PROPERTY_TYPES }
      end

      # GET /api/v1/reference/sale_statuses
      def sale_statuses
        set_long_cache_headers
        render json: {
          data: [
            { value: "for_sale", label: I18n.t("ui.properties.sale_statuses.for_sale", default: "For Sale") },
            { value: "for_rent", label: I18n.t("ui.properties.sale_statuses.for_rent", default: "For Rent") }
          ]
        }
      end

      # GET /api/v1/reference/sort_options
      def sort_options
        set_long_cache_headers
        render json: {
          data: [
            { value: "recommended", label: I18n.t("ui.searches.sort_options.recommended", default: "Recommended") },
            { value: "newest",      label: I18n.t("ui.searches.sort_options.newest",      default: "Newest") },
            { value: "price_asc",   label: I18n.t("ui.searches.sort_options.price_low",   default: "Price: low to high") },
            { value: "price_desc",  label: I18n.t("ui.searches.sort_options.price_high",  default: "Price: high to low") }
          ]
        }
      end

      # GET /api/v1/reference/languages
      def languages
        set_long_cache_headers
        codes = AppSettings.available_languages || %w[en]
        render json: {
          data: codes.map { |code| { code: code.to_s, label: language_label(code) } }
        }
      end

      # GET /api/v1/reference/booking_window
      def booking_window
        config = BookingConfiguration.current
        response.set_header("Cache-Control", "public, max-age=300")
        response.set_header("ETag", %("booking-config-#{config.updated_at.to_i}"))
        if request.headers["If-None-Match"] == response.headers["ETag"]
          head :not_modified and return
        end

        render json: {
          slot_duration_minutes:    config.slot_duration_minutes,
          booking_window_days:      config.booking_window_days,
          lead_time_hours:          config.lead_time_hours,
          buffer_minutes:           config.buffer_minutes,
          office_opens_at:          config.office_opens_at,
          office_closes_at:         config.office_closes_at,
          open_weekdays:            config.open_weekday_numbers,
          supported_slot_durations: BookingConfiguration::SUPPORTED_SLOT_DURATIONS
        }
      end

      private

      def set_long_cache_headers
        response.set_header("Cache-Control", "public, max-age=86400")
      end

      def language_label(code)
        I18n.t("languages.#{code}", default: code.to_s.upcase)
      end
    end
  end
end
