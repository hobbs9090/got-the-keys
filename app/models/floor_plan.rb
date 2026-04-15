class FloorPlan < ApplicationRecord
  FILE_UPLOAD_EXTENSIONS = %w[.pdf .jpg .jpeg .png .webp].freeze
  FILE_UPLOAD_CONTENT_TYPES = %w[application/pdf image/jpeg image/pjpeg image/jpg image/png image/webp].freeze
  UPLOADED_FILE_PREFIX = "/uploads/property_floor_plans/".freeze

  attr_accessor :floor_plan_upload

  belongs_to :property

  before_validation :assign_uploaded_filename

  validates :floor_plans, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :floor_plan_upload_is_supported

  scope :ordered, -> { order(:position, :id) }

  after_save_commit :persist_floor_plan_upload!, if: -> { floor_plan_upload.present? }
  after_destroy_commit :remove_uploaded_floor_plan_file

  private

  def assign_uploaded_filename
    return if floor_plan_upload.blank?
    return if floor_plans.present?

    self.floor_plans = floor_plan_upload.original_filename.to_s
  end

  def floor_plan_upload_is_supported
    return if floor_plan_upload.blank?

    extension = File.extname(floor_plan_upload.original_filename.to_s).downcase
    content_type = floor_plan_upload.content_type.to_s
    return if extension.in?(FILE_UPLOAD_EXTENSIONS) && (content_type.blank? || content_type.in?(FILE_UPLOAD_CONTENT_TYPES))

    errors.add(:floor_plan_upload, I18n.t("ui.floor_plans.validation.upload", default: "must be a PDF or image file"))
  end

  def persist_floor_plan_upload!
    return if floor_plan_upload.blank? || !persisted?

    extension = File.extname(floor_plan_upload.original_filename.to_s).downcase
    filename = "#{SecureRandom.hex(16)}#{extension}"
    relative_path = File.join("property_floor_plans", property_id.to_s, id.to_s, filename)
    absolute_path = upload_root.join(relative_path)
    previous_file_path = floor_plans if uploaded_floor_plan_path?(floor_plans)

    FileUtils.mkdir_p(absolute_path.dirname)
    floor_plan_upload.rewind if floor_plan_upload.respond_to?(:rewind)
    File.binwrite(absolute_path, floor_plan_upload.read)

    new_file_path = "/uploads/#{relative_path}"
    update_column(:floor_plans, new_file_path)
    self.floor_plans = new_file_path
    self.floor_plan_upload = nil

    purge_uploaded_file(previous_file_path) if previous_file_path.present? && previous_file_path != new_file_path
  end

  def remove_uploaded_floor_plan_file
    purge_uploaded_file(floor_plans)
  end

  def upload_root
    if Rails.env.test?
      Rails.root.join("tmp", "uploads")
    else
      Rails.root.join("public", "uploads")
    end
  end

  def uploaded_floor_plan_path?(path)
    path.to_s.start_with?(UPLOADED_FILE_PREFIX)
  end

  def uploaded_file_absolute_path(path)
    return if path.blank? || !uploaded_floor_plan_path?(path)

    upload_root.join(path.delete_prefix("/uploads/"))
  end

  def purge_uploaded_file(path)
    absolute_path = uploaded_file_absolute_path(path)
    return if absolute_path.blank? || !absolute_path.exist?

    absolute_path.delete
    prune_empty_upload_directories_from(absolute_path.dirname)
  end

  def prune_empty_upload_directories_from(directory)
    root_directory = upload_root.join("property_floor_plans")
    current_directory = directory

    while current_directory.to_s.start_with?(root_directory.to_s) && current_directory.exist? && current_directory.children.empty?
      parent_directory = current_directory.dirname
      current_directory.rmdir
      current_directory = parent_directory
    end
  end
end
