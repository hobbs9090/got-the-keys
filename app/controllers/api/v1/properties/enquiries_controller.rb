module Api
  module V1
    module Properties
      class EnquiriesController < BaseController
        # POST /api/v1/properties/:property_id/enquiries
        def create
          property = Property.publicly_visible.find_by(id: params[:property_id])
          return render_not_found if property.nil?

          enquiry = property.enquiries.build(enquiry_params)
          # Always trust the authenticated user's identity, never the request body.
          enquiry.customer_name  = current_user.full_name.presence || current_user.email
          enquiry.customer_email = current_user.email
          enquiry.customer_phone = current_user.mobile_number

          if enquiry.save
            render json: EnquiryResource.render(enquiry,
                                                  current_user: current_user,
                                                  host: api_host),
                   status: :created
          else
            render_validation_error(enquiry)
          end
        end

        private

        def enquiry_params
          params.permit(:message, :source_type).to_h.tap do |attrs|
            attrs["source_type"] ||= "general_enquiry"
          end
        end

        def api_host
          "#{request.protocol}#{request.host_with_port}"
        end
      end
    end
  end
end
