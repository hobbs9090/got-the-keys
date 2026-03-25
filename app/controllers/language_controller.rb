class LanguageController < ApplicationController
  def new
    language = params.require(:language)
    raise ActionController::BadRequest, 'unsupported language' unless available_languages.include?(language)

    session[:language] = language
    persist_signed_in_language(language)

    redirect_back fallback_location: root_path
  end

  private

  def persist_signed_in_language(language)
    return unless current_user || current_admin

    (current_user || current_admin).update_column(:language, language)
  end
end
