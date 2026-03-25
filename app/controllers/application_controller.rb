class ApplicationController < ActionController::Base
  before_action :set_user_language
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper AppVersionHelper
  helper_method :available_languages, :booking_configuration, :chinese_locale?,
                :cookie_consent_choice, :cookie_consent_pending?, :cookie_consent_all?,
                :cookie_consent_essential_only?

  protected

  def configure_permitted_parameters
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
end
