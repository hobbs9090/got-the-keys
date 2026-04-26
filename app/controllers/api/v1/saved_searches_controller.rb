module Api
  module V1
    class SavedSearchesController < BaseController
      before_action :load_search, only: [:update, :destroy]

      # GET /api/v1/saved_searches
      def index
        scope = current_user.saved_searches.order(created_at: :desc)
        paginated = paginate(scope)
        data = paginated.map { |s| SavedSearchResource.render(s) }
        render json: { data: data, meta: pagination_meta(paginated), links: pagination_links(paginated) }
      end

      # POST /api/v1/saved_searches
      def create
        attrs = saved_search_params
        attrs[:locale] ||= I18n.locale.to_s
        search = current_user.saved_searches.new(attrs)
        if search.save
          render json: SavedSearchResource.render(search), status: :created
        else
          render_validation_error(search)
        end
      end

      # PATCH /api/v1/saved_searches/:id
      def update
        if @saved_search.update(saved_search_params)
          render json: SavedSearchResource.render(@saved_search)
        else
          render_validation_error(@saved_search)
        end
      end

      # DELETE /api/v1/saved_searches/:id
      def destroy
        @saved_search.destroy!
        head :no_content
      end

      private

      def load_search
        @saved_search = current_user.saved_searches.find_by(id: params[:id])
        render_not_found if @saved_search.nil?
      end

      def saved_search_params
        permitted = params.permit(:search_query, :sale_status, :town_city, :min_bedrooms,
                                  :min_price_pence, :max_price_pence, :sort, :alerts_enabled,
                                  :locale).to_h.with_indifferent_access

        # Translate API enum keys to model values.
        if permitted[:sale_status].present?
          permitted[:sale_status] = case permitted[:sale_status].to_s.downcase
                                    when "for_sale" then Property::SALE_STATUSES[:for_sale]
                                    when "for_rent" then Property::SALE_STATUSES[:for_rent]
                                    else permitted[:sale_status]
                                    end
        end

        if permitted[:sort].present?
          permitted[:sort] = case permitted[:sort].to_s
                             when "price_asc"  then "price_low"
                             when "price_desc" then "price_high"
                             else permitted[:sort]
                             end
        end

        # Map *_pence to model fields (which are already integer pence).
        permitted[:min_price] = permitted.delete(:min_price_pence) if permitted.key?(:min_price_pence)
        permitted[:max_price] = permitted.delete(:max_price_pence) if permitted.key?(:max_price_pence)

        permitted
      end
    end
  end
end
