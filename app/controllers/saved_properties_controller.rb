class SavedPropertiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property
  before_action :prevent_owner_save!

  def create
    current_user.saved_properties.find_or_create_by!(property: @property)

    redirect_to property_path(@property), notice: t("ui.saved_properties.saved_notice", default: "Property saved.")
  end

  def destroy
    current_user.saved_properties.where(property: @property).destroy_all

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to property_path(@property), notice: t("ui.saved_properties.removed_notice", default: "Property removed from saved homes.") }
    end
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def prevent_owner_save!
    return unless @property.user == current_user

    redirect_to property_path(@property), alert: t("ui.saved_properties.owner_alert", default: "You cannot save your own listing.")
  end
end
