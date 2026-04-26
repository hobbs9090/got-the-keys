module Api
  module V1
    class SavedPropertiesController < BaseController
      # GET /api/v1/saved_properties
      def index
        scope = current_user.saved_properties
                            .includes(property: [:photos, :user])
                            .order(created_at: :desc)
        paginated = paginate(scope)

        host = "#{request.protocol}#{request.host_with_port}"
        properties = paginated.map(&:property).compact
        slots = PropertyNextAvailableSlotLookup.new(properties: properties).call(limit: 1)

        data = paginated.map do |saved|
          property = saved.property
          next nil if property.nil?

          PropertySummaryResource.render(property,
                                          current_user: current_user,
                                          host: host,
                                          next_slot: slots[property.id]).merge(
            saved_at: saved.created_at&.utc&.iso8601
          )
        end.compact

        render json: { data: data, meta: pagination_meta(paginated), links: pagination_links(paginated) }
      end

      # POST /api/v1/saved_properties
      # Body: { "property_id": 42 }
      def create
        property = Property.publicly_visible.find_by(id: params[:property_id])
        return render_not_found if property.nil?

        if property.user_id == current_user.id
          return render_error(
            status: :unprocessable_entity, code: "validation_failed",
            message: I18n.t("api.errors.cannot_save_own_property",
                             default: "You cannot save your own listing."),
            details: [{ field: "property_id", code: "invalid", message: "cannot save your own listing" }]
          )
        end

        saved = current_user.saved_properties.find_or_create_by!(property: property)
        render json: {
          id:        saved.id,
          property_id: saved.property_id,
          saved_at:  saved.created_at&.utc&.iso8601
        }, status: :created
      end

      # DELETE /api/v1/saved_properties/:property_id
      def destroy
        saved = current_user.saved_properties.find_by(property_id: params[:property_id])
        return render_not_found if saved.nil?

        saved.destroy!
        head :no_content
      end
    end
  end
end
