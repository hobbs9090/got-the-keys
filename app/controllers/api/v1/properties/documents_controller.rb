module Api
  module V1
    module Properties
      # Document downloads. Public documents are accessible without auth; private
      # documents require an authenticated owner — but in the buyer/renter v1
      # scope, only public documents are exposed at all (the private ones live
      # behind seller/admin endpoints, which are out-of-scope for v1).
      class DocumentsController < BaseController
        skip_before_action :authenticate_api_user!
        before_action :authenticate_api_user_optional

        # GET /api/v1/properties/:property_id/documents/:id/download
        def download
          property = Property.publicly_visible.find_by(id: params[:property_id])
          return render_not_found if property.nil?

          document = property.property_documents.find_by(id: params[:id])
          return render_not_found if document.nil?

          unless document.publicly_visible? || current_user&.id == property.user_id
            return render_forbidden
          end

          # Best-effort audit, mirrors the web flow.
          begin
            AuditLogger.log!(
              auditable:  document,
              property:   property,
              actor_label: current_user&.email.presence || I18n.t("ui.property_documents.public_visitor",
                                                                   default: "Public visitor"),
              action:     "property_document_downloaded",
              message:    I18n.t("ui.property_documents.audit.downloaded",
                                  title: document.title,
                                  default: "Document downloaded: #{document.title}")
            )
          rescue StandardError => e
            Rails.logger.warn("[api] document audit log failed: #{e.class}: #{e.message}")
          end

          send_data(
            PropertyDocumentPayloadBuilder.new(document: document, property: property).payload,
            filename: document.file_name,
            disposition: "attachment",
            type: mime_type_for(document.file_name)
          )
        end

        private

        def mime_type_for(file_name)
          case File.extname(file_name.to_s).downcase
          when ".pdf" then "application/pdf"
          when ".doc" then "application/msword"
          when ".docx" then "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
          when ".jpg", ".jpeg" then "image/jpeg"
          when ".png" then "image/png"
          else "application/octet-stream"
          end
        end
      end
    end
  end
end
