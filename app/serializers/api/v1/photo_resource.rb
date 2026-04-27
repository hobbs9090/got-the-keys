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
          filename = photo.image_filename.to_s
          if filename.start_with?(Photo::UPLOADED_IMAGE_PREFIX)
            "#{host}#{filename}"
          else
            "#{host}#{ActionController::Base.helpers.asset_path(filename)}"
          end
        end
      end
    end
  end
end
