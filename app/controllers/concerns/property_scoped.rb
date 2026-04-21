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

  # Seller workspace links are also shown on admin property edits; allow staff without a seller session.
  def authenticate_user_or_admin!
    return if user_signed_in? || admin_signed_in?

    authenticate_user!
  end

  def authorize_property_owner_or_admin!
    return if current_admin.present?
    return if @property.user == current_user

    redirect_to root_path, alert: t(:not_authorised)
  end
end
