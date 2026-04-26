module Api
  module V1
    class PhotoResource
      class << self
        def render(photo, host:)
          {
            id:       photo.id,
            url:      url_for_photo(photo, host: host),
            caption:  photo.caption,
            primary:  photo.primary?,
            position: photo.position
          }
        end

        def url_for_photo(photo, host:)
          path = "/uploads/property_photos/#{photo.property_id}/#{photo.id}/#{photo.image_filename}"
          "#{host}#{path}"
        end
      end
    end
  end
end
