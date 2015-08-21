class LanguageController < ApplicationController

  def new
    language = params[:language]
    raise 'unsupported location' unless LANGUAGES.include?(language)
    if user_signed_in?
      current_user.language = language
      current_user.save
    elsif admin_signed_in?
      current_admin.language = language
      current_admin.save
    else
      Rails.logger.debug 'DEBUG: Oops'
    end
    redirect_to :back
  end

end
