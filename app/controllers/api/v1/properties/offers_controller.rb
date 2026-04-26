module Api
  module V1
    module Properties
      class OffersController < BaseController
        # POST /api/v1/properties/:property_id/offers
        def create
          property = Property.publicly_visible.find_by(id: params[:property_id])
          return render_not_found if property.nil?

          unless property.sale_status == Property::SALE_STATUSES[:for_sale]
            return render_error(
              status: :unprocessable_entity, code: "validation_failed",
              message: I18n.t("api.errors.offer_requires_sale_listing",
                               default: "Offers can only be made on sale listings."),
              details: [{ field: "property_id", code: "invalid", message: "must be a sale listing" }]
            )
          end

          offer = property.offers.build(
            buyer_name:     current_user.full_name.presence || current_user.email,
            buyer_email:    current_user.email,
            buyer_phone:    current_user.mobile_number.presence || "0000000000",
            amount:         offer_amount_pence,
            chain_position: params[:chain_position].to_s.strip.presence,
            notes:          params[:notes].to_s.strip.presence
          )

          if offer.save
            render json: OfferResource.render(offer, current_user: current_user, host: api_host),
                   status: :created
          else
            render_validation_error(offer)
          end
        end

        private

        # API takes amount_pence; model amount is integer pence already.
        def offer_amount_pence
          raw = params[:amount_pence].presence || params[:amount].presence
          raw.to_s.gsub(/[,\s]/, "").to_i
        end

        def api_host
          "#{request.protocol}#{request.host_with_port}"
        end
      end
    end
  end
end
