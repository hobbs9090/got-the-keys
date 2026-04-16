class SavedSearchesController < ApplicationController
  include SavedSearchCatalogueRedirects

  before_action :require_saved_search_identity!

  def create
    form = saved_search_form_params
    @saved_search = saved_search_owner.saved_searches.build(form.except(:catalogue_scope))
    redirect_scope = catalogue_scope_from_saved_search_form

    if @saved_search.save
      matches = @saved_search.matching_properties_count
      redirect_to catalogue_redirect_path_for(@saved_search.filter_params, redirect_scope),
                    notice: t("ui.saved_searches.notice", count: matches, display_count: helpers.display_number(matches))
    else
      redirect_to catalogue_redirect_path_for(@saved_search.filter_params, redirect_scope),
                    alert: @saved_search.errors.full_messages.to_sentence
    end
  end

  def destroy
    search = saved_search_owner.saved_searches.find(params[:id])
    filter_params = search.filter_params
    scope = catalogue_scope_for_destroy(search)
    search.destroy!
    redirect_to catalogue_redirect_path_for(filter_params, scope), notice: t("ui.saved_searches.destroyed")
  end

  private

  def require_saved_search_identity!
    return if saved_search_owner.present?

    redirect_to(new_user_session_path)
  end

  def saved_search_owner
    return @saved_search_owner if defined?(@saved_search_owner)

    @saved_search_owner =
      if current_user.present?
        current_user
      elsif current_admin.present?
        User.find_by(email: current_admin.email) || provision_admin_saved_search_user
      end
  end

  def provision_admin_saved_search_user
    generated_password = SecureRandom.hex(16)

    User.create!(
      email: current_admin.email,
      first_name: "Admin",
      last_name: "User",
      mobile_number: "07000000000",
      language: I18n.default_locale.to_s,
      terms_of_service: true,
      password: generated_password,
      password_confirmation: generated_password
    )
  rescue ActiveRecord::RecordNotUnique
    User.find_by(email: current_admin.email)
  end

  def saved_search_form_params
    params.require(:saved_search).permit(
      :locale, :sale_status, :search_query, :town_city, :min_bedrooms,
      :min_price, :max_price, :sort, :alerts_enabled, :catalogue_scope
    )
  end
end
