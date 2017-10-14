class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_user_language

  before_filter :update_sanitized_params, if: :devise_controller?

  #before_filter :miniprofiler

  def update_sanitized_params
    # TODO devise_parameter_sanitizer.sanitize OR devise_parameter_sanitizer.for?
    devise_parameter_sanitizer.permit(:sign_up) {|u| u.permit(:first_name, :last_name, :mobile_number, :email, :password, :password_confirmation, :language, :terms_of_service)}
    devise_parameter_sanitizer.permit(:update) {|u| u.permit(:first_name, :last_name, :mobile_number, :email, :password, :password_confirmation, :language)}
  end

  private

  def set_user_language
    if user_signed_in?
      I18n.locale = current_user.language
    elsif admin_signed_in?
      I18n.locale = current_admin.language
    else
      I18n.locale = I18n.default_locale
    end
  end

  #def miniprofiler
  #  Rack::MiniProfiler.authorize_request if admin_signed_in?
  #end

end
