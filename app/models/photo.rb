class Photo < ApplicationRecord
  IMAGE_UPLOAD_EXTENSIONS = %w[.jpg .jpeg .png .webp .gif].freeze
  IMAGE_UPLOAD_CONTENT_TYPES = %w[image/jpeg image/pjpeg image/jpg image/png image/webp image/gif].freeze
  UPLOADED_IMAGE_PREFIX = "/uploads/property_photos/".freeze

  attr_accessor :image_upload

  belongs_to :property

  before_validation :assign_uploaded_filename

  validates :image_filename, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :image_upload_is_supported

  scope :ordered, -> { order(primary: :desc, position: :asc, id: :asc) }

  after_save_commit :clear_other_primary_flags, if: :primary?
  after_save_commit :persist_image_upload!, if: -> { image_upload.present? }
  after_destroy_commit :remove_uploaded_image_file

  private

  def assign_uploaded_filename
    return if image_upload.blank?
    return if image_filename.present?

    self.image_filename = image_upload.original_filename.to_s
  end

  def image_upload_is_supported
    return if image_upload.blank?

    extension = File.extname(image_upload.original_filename.to_s).downcase
    content_type = image_upload.content_type.to_s
    return if extension.in?(IMAGE_UPLOAD_EXTENSIONS) && (content_type.blank? || content_type.in?(IMAGE_UPLOAD_CONTENT_TYPES))

    errors.add(:image_upload, I18n.t("ui.properties.validation.image_upload", default: "must be a JPG or JPEG image"))
  end

  def persist_image_upload!
    return if image_upload.blank? || !persisted?

    extension = File.extname(image_upload.original_filename.to_s).downcase
    filename = "#{SecureRandom.hex(16)}#{extension}"
    relative_path = File.join("property_photos", property_id.to_s, id.to_s, filename)
    absolute_path = image_upload_root.join(relative_path)
    previous_image_path = image_filename if uploaded_photo_image_path?(image_filename)

    FileUtils.mkdir_p(absolute_path.dirname)
    image_upload.rewind if image_upload.respond_to?(:rewind)
    File.binwrite(absolute_path, image_upload.read)

    new_image_path = "/uploads/#{relative_path}"
    update_column(:image_filename, new_image_path)
    self.image_filename = new_image_path
    self.image_upload = nil

    purge_uploaded_image(previous_image_path) if previous_image_path.present? && previous_image_path != new_image_path
  end

  def clear_other_primary_flags
    property.photos.where.not(id: id).where(primary: true).update_all(primary: false)
  end

  def remove_uploaded_image_file
    purge_uploaded_image(image_filename)
  end

  def image_upload_root
    if Rails.env.test?
      Rails.root.join("tmp", "uploads")
    else
      Rails.root.join("public", "uploads")
    end
  end

  def uploaded_photo_image_path?(path)
    path.to_s.start_with?(UPLOADED_IMAGE_PREFIX)
  end

  def uploaded_image_absolute_path(path)
    return if path.blank? || !uploaded_photo_image_path?(path)

    image_upload_root.join(path.delete_prefix("/uploads/"))
  end

  def purge_uploaded_image(path)
    absolute_path = uploaded_image_absolute_path(path)
    return if absolute_path.blank? || !absolute_path.exist?

    absolute_path.delete
    prune_empty_upload_directories_from(absolute_path.dirname)
  end

  def prune_empty_upload_directories_from(directory)
    root_directory = image_upload_root.join("property_photos")
    current_directory = directory

    while current_directory.to_s.start_with?(root_directory.to_s) && current_directory.exist? && current_directory.children.empty?
      parent_directory = current_directory.dirname
      current_directory.rmdir
      current_directory = parent_directory
    end
  end
end
