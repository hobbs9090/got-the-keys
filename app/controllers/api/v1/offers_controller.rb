module Api
  module V1
    class OffersController < BaseController
      before_action :load_offer, only: %i[show withdraw]

      # GET /api/v1/offers
      def index
        scope = current_user_offers_scope
        scope = filter_by_status(scope) if params[:status].present?
        scope = scope.includes(:property, :offer_events)

        render_collection(
          collection_serializer: method(:serialize_collection),
          scope: scope.recent_first
        )
      end

      # GET /api/v1/offers/:public_reference
      def show
        render json: OfferResource.render(@offer,
                                            current_user: current_user,
                                            host: api_host)
      end

      # PATCH /api/v1/offers/:public_reference/withdraw
      def withdraw
        unless @offer.withdrawable?
          return render_error(
            status: :conflict, code: "conflict",
            message: I18n.t("api.errors.offer_not_withdrawable",
                             default: "This offer can no longer be withdrawn.")
          )
        end

        if @offer.update(status: "withdrawn")
          render json: OfferResource.render(@offer,
                                              current_user: current_user,
                                              host: api_host)
        else
          render_validation_error(@offer)
        end
      end

      private

      def current_user_offers_scope
        Offer.where("lower(buyer_email) = ?", current_user.email.to_s.downcase)
      end

      def filter_by_status(scope)
        statuses = Array(params[:status]).map(&:to_s) & Offer::STATUSES
        return scope if statuses.empty?

        scope.where(status: statuses)
      end

      def load_offer
        @offer = current_user_offers_scope
                   .includes(:property, :offer_events)
                   .find_by(public_reference: params[:public_reference])
        render_not_found if @offer.nil?
      end

      def serialize_collection(records, current_user:)
        host = api_host
        records.map { |o| OfferResource.render(o, current_user: current_user, host: host) }
      end

      def api_host
        "#{request.protocol}#{request.host_with_port}"
      end
    end
  end
end
