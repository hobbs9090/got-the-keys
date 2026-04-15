require "rails_helper"

RSpec.describe SavedProperty do
  it "does not allow the property owner to save their own listing" do
    property = FactoryBot.create(:property)
    owner = property.user

    saved_property = FactoryBot.build(:saved_property, user: owner, property: property)

    expect(saved_property).not_to be_valid
    expect(saved_property.errors[:property]).to include(I18n.t("ui.saved_properties.validation.owner_cannot_save"))
  end
end
