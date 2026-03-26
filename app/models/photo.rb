class Photo < ApplicationRecord
  belongs_to :property

  validates :image_filename, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(primary: :desc, position: :asc, id: :asc) }

  after_save_commit :clear_other_primary_flags, if: :primary?

  private

  def clear_other_primary_flags
    property.photos.where.not(id: id).where(primary: true).update_all(primary: false)
  end
end
