module Api
  module V1
    class DocumentResource
      class << self
        def render(document)
          {
            id:             document.id,
            title:          document.title,
            category:       document.category,
            category_label: document.respond_to?(:category_label) ? document.category_label : document.category,
            visibility:     document.visibility,
            position:       document.position,
            is_pdf:         document.respond_to?(:pdf?) ? document.pdf? : document.file_name.to_s.downcase.end_with?(".pdf"),
            download_url:   "/api/v1/properties/#{document.property_id}/documents/#{document.id}/download"
          }
        end
      end
    end
  end
end
