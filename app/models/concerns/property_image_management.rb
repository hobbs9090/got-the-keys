module PropertyImageManagement
  extend ActiveSupport::Concern

  IMAGE_FILE_NAME_FORMAT = /\A[\w.\-\/]+\.(gif|jpg|jpeg|png|svg|webp)\z/i.freeze
  IMAGE_UPLOAD_EXTENSIONS = %w[.jpg .jpeg].freeze
  IMAGE_UPLOAD_CONTENT_TYPES = %w[image/jpeg image/pjpeg image/jpg].freeze
  UPLOADED_IMAGE_PREFIX = "/uploads/property_images/".freeze

  included do
    attr_accessor :image_upload

    validates :image_file_name,
              allow_blank: true,
              format: {
                with: IMAGE_FILE_NAME_FORMAT,
                message: ->(_record, _data) { I18n.t("ui.properties.validation.image_file_name", default: "must reference a GIF, JPG, JPEG, PNG, SVG, or WEBP image") }
              }

    validate :image_upload_is_jpeg
    after_destroy_commit :remove_uploaded_image_file
  end

  def persist_image_upload!
    return if image_upload.blank? || !persisted?

    extension = File.extname(image_upload.original_filename.to_s).downcase
    filename = "#{SecureRandom.hex(16)}#{extension}"
    relative_path = File.join("property_images", id.to_s, filename)
    absolute_path = image_upload_root.join(relative_path)
    previous_image_path = image_file_name if uploaded_property_image_path?(image_file_name)

    FileUtils.mkdir_p(absolute_path.dirname)
    image_upload.rewind if image_upload.respond_to?(:rewind)
    File.binwrite(absolute_path, image_upload.read)

    new_image_path = "/uploads/#{relative_path}"
    update_column(:image_file_name, new_image_path)
    self.image_file_name = new_image_path
    self.image_upload = nil

    purge_uploaded_image(previous_image_path) if previous_image_path.present? && previous_image_path != new_image_path
  end

  private

  def image_upload_is_jpeg
    return if image_upload.blank?

    extension = File.extname(image_upload.original_filename.to_s).downcase
    content_type = image_upload.content_type.to_s

    return if extension.in?(IMAGE_UPLOAD_EXTENSIONS) && (content_type.blank? || content_type.in?(IMAGE_UPLOAD_CONTENT_TYPES))

    errors.add(:image_upload, I18n.t("ui.properties.validation.image_upload", default: "must be a JPG or JPEG image"))
  end

  def image_upload_root
    if Rails.env.test?
      Rails.root.join("tmp", "uploads")
    else
      Rails.root.join("public", "uploads")
    end
  end

  def uploaded_property_image_path?(path)
    path.to_s.start_with?(UPLOADED_IMAGE_PREFIX)
  end

  def uploaded_image_absolute_path(path)
    return if path.blank? || !uploaded_property_image_path?(path)

    candidate = image_upload_root.join(path.delete_prefix("/uploads/"))
    return unless candidate.expand_path.to_s.start_with?(image_upload_root.expand_path.to_s)

    candidate
  end

  def purge_uploaded_image(path)
    absolute_path = uploaded_image_absolute_path(path)
    return if absolute_path.blank? || !absolute_path.exist?

    absolute_path.delete
    prune_empty_upload_directories_from(absolute_path.dirname)
  end

  def prune_empty_upload_directories_from(directory)
    root_directory = image_upload_root.join("property_images")
    current_directory = directory

    while current_directory.to_s.start_with?(root_directory.to_s) && current_directory.exist? && current_directory.children.empty?
      parent_directory = current_directory.dirname
      current_directory.rmdir
      current_directory = parent_directory
    end
  end

  def remove_uploaded_image_file
    purge_uploaded_image(image_file_name)
  end
end
