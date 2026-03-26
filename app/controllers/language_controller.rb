class LanguageController < ApplicationController
  def new
    language = params.require(:language)
    raise ActionController::BadRequest, 'unsupported language' unless available_languages.include?(language)

    session[:language] = language
    persist_signed_in_language(language)

    redirect_to(language_return_path)
  end

  private

  def persist_signed_in_language(language)
    return unless current_user || current_admin

    (current_user || current_admin).update_column(:language, language)
  end

  def language_return_path
    safe_return_path || fallback_return_path
  end

  def safe_return_path
    return_to = params[:return_to].to_s
    return if return_to.blank?
    return if return_to.include?("://")
    return if return_to.start_with?("//")
    return unless return_to.start_with?("/")

    return_to
  end

  def fallback_return_path
    request.referer.presence || root_path
  end
end
