class CookiePreferencesController < ApplicationController
  VALID_PREFERENCES = %w[all essential].freeze

  skip_before_action :set_user_language
  skip_forgery_protection
  before_action :skip_session_storage

  def update
    preference = params[:preference].to_s

    if VALID_PREFERENCES.include?(preference)
      cookies.permanent[:gotthekeys_cookie_consent] = {
        value: preference,
        same_site: :lax
      }
    end

    redirect_to safe_return_path
  end

  private

  def skip_session_storage
    request.session_options[:skip] = true
  end

  def safe_return_path
    return_to = params[:return_to].to_s

    if return_to.start_with?("/") && !return_to.start_with?("//")
      return_to
    else
      cookie_policy_index_path(anchor: "cookie-preferences")
    end
  end
end
