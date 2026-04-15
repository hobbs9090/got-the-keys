class SavedProperty < ApplicationRecord
  belongs_to :user
  belongs_to :property

  validates :property_id, uniqueness: { scope: :user_id }
  validate :property_cannot_belong_to_user

  private

  def property_cannot_belong_to_user
    return if user.blank? || property.blank?
    return unless property.user == user

    errors.add(:property, I18n.t("ui.saved_properties.validation.owner_cannot_save", default: "cannot belong to the owner"))
  end
end
