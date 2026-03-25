module PropertyScoped
  extend ActiveSupport::Concern

  private

  def set_property
    @property = Property.find(params[:property_id] || params[:id])
  end

  def authorize_property_owner!
    return if @property.user == current_user

    redirect_to root_path, alert: t(:not_authorised)
  end
end
