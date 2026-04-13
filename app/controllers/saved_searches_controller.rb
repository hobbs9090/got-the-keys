class SavedSearchesController < ApplicationController
  include SavedSearchCatalogueRedirects

  before_action :authenticate_user!

  def create
    form = saved_search_form_params
    @saved_search = current_user.saved_searches.build(form.except(:catalogue_scope))
    redirect_scope = catalogue_scope_from_saved_search_form

    if @saved_search.save
      matches = @saved_search.matching_properties_count
      redirect_to catalogue_redirect_path_for(@saved_search.filter_params, redirect_scope),
                    notice: t("ui.saved_searches.notice", count: matches)
    else
      redirect_to catalogue_redirect_path_for(@saved_search.filter_params, redirect_scope),
                    alert: @saved_search.errors.full_messages.to_sentence
    end
  end

  def destroy
    search = current_user.saved_searches.find(params[:id])
    filter_params = search.filter_params
    scope = catalogue_scope_for_destroy(search)
    search.destroy!
    redirect_to catalogue_redirect_path_for(filter_params, scope), notice: t("ui.saved_searches.destroyed")
  end

  private

  def saved_search_form_params
    params.require(:saved_search).permit(
      :locale, :sale_status, :search_query, :town_city, :min_bedrooms,
      :min_price, :max_price, :sort, :alerts_enabled, :catalogue_scope
    )
  end
end
