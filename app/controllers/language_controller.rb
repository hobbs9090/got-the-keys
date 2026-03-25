class LanguageController < ApplicationController
  def new
    language = params.require(:language)
    raise ActionController::BadRequest, 'unsupported language' unless available_languages.include?(language)

    (current_user || current_admin)&.update(language: language)

    redirect_back fallback_location: root_path
  end
end
