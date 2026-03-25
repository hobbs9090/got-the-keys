class ApplicationController < ActionController::Base
  before_action :set_user_language
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :available_languages, :chinese_locale?

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

  def available_languages
    AppSettings.available_languages
  end

  def chinese_locale?
    I18n.locale.to_sym == :zh
  end

  def set_user_language
    I18n.locale = current_user&.language || current_admin&.language || I18n.default_locale
  end
end
