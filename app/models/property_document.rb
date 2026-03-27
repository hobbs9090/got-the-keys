class PropertyDocument < ApplicationRecord
  CATEGORIES = %w[brochure compliance landlord_attachment vendor_attachment epc tenancy_info].freeze
  VISIBILITIES = %w[public private].freeze
  FILE_NAME_FORMAT = /\A[\w.\-\/ ]+\.(pdf|doc|docx|jpg|jpeg|png)\z/i.freeze

  belongs_to :property

  has_many :audit_logs, as: :auditable, dependent: :destroy

  validates :title, :file_name, :category, :visibility, presence: true
  validates :title, length: { maximum: 120 }
  validates :file_name, length: { maximum: 200 }, format: { with: FILE_NAME_FORMAT, message: ->(_record, _data) { I18n.t("ui.property_documents.validation.supported_file") } }
  validates :category, inclusion: { in: CATEGORIES }
  validates :visibility, inclusion: { in: VISIBILITIES }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
  scope :publicly_visible, -> { where(visibility: "public") }

  def category_label
    I18n.t("ui.property_documents.categories.#{category}", default: category.to_s.tr("_", " ").humanize)
  end

  def visibility_label
    I18n.t("ui.property_documents.visibilities.#{visibility}", default: visibility.humanize)
  end

  def publicly_visible?
    visibility == "public"
  end
end
