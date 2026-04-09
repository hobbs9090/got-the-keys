class ApplicationController < ActionController::Base
  before_action :set_user_language
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper AppVersionHelper
  helper_method :available_languages, :booking_configuration, :chinese_locale?,
                :cookie_consent_choice, :cookie_consent_pending?, :cookie_consent_all?,
                :cookie_consent_essential_only?, :homepage_from_admin_referrer?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[otp_attempt])
    devise_parameter_sanitizer.permit(
      :sign_up,
      keys: %i[first_name last_name mobile_number email password password_confirmation language terms_of_service]
    )
    devise_parameter_sanitizer.permit(
      :account_update,
      keys: %i[first_name last_name mobile_number email password password_confirmation language]
    )
  end

  private

  def after_sign_in_path_for(resource)
    if resource.is_a?(User)
      save_requested_property_for(resource)

      return requested_return_path if requested_return_path.present?
    end

    super
  end

  def after_sign_up_path_for(resource)
    if resource.is_a?(User)
      save_requested_property_for(resource)

      return requested_return_path if requested_return_path.present?
    end

    super
  end

  def after_inactive_sign_up_path_for(resource)
    if resource.is_a?(User)
      save_requested_property_for(resource)

      return requested_return_path if requested_return_path.present?
    end

    super
  end

  def cookie_consent_choice
    value = cookies[:gotthekeys_cookie_consent].presence
    %w[all essential].include?(value) ? value : nil
  end

  def cookie_consent_pending?
    cookie_consent_choice.blank?
  end

  def cookie_consent_all?
    cookie_consent_choice == "all"
  end

  def cookie_consent_essential_only?
    cookie_consent_choice == "essential"
  end

  def available_languages
    AppSettings.available_languages
  end

  def chinese_locale?
    I18n.locale.to_sym == :zh
  end

  def booking_configuration
    BookingConfiguration.current
  end

  def set_user_language
    preferred_language = current_user&.language || current_admin&.language || session[:language]
    I18n.locale = available_languages.include?(preferred_language.to_s) ? preferred_language : I18n.default_locale
  end

  def homepage_from_admin_referrer?
    return false unless controller_path == "welcome"
    return false if request.referer.blank?

    URI.parse(request.referer).path.match?(%r{\A/admin(?:/|$)})
  rescue URI::InvalidURIError
    false
  end

  def save_requested_property_for(resource)
    property_id = params[:save_property_id].presence
    return if property_id.blank?

    property = Property.find_by(id: property_id)
    return if property.blank? || property.user == resource

    resource.saved_properties.find_or_create_by!(property:)
  end

  def requested_return_path
    path = params[:return_to].to_s
    return if path.blank?
    return path if path.start_with?("/")

    nil
  end
end
