class SavedSearchesController < ApplicationController
  before_action :authenticate_user!

  def create
    @saved_search = current_user.saved_searches.build(saved_search_params)

    if @saved_search.save
      matches = @saved_search.matching_properties_count
      redirect_to properties_path(@saved_search.filter_params), notice: t("ui.saved_searches.notice", count: matches)
    else
      redirect_to properties_path(@saved_search.filter_params), alert: @saved_search.errors.full_messages.to_sentence
    end
  end

  def destroy
    search = current_user.saved_searches.find(params[:id])
    filter_params = search.filter_params
    search.destroy!
    redirect_to properties_path(filter_params), notice: t("ui.saved_searches.destroyed")
  end

  private

  def saved_search_params
    params.require(:saved_search).permit(:locale, :sale_status, :search_query, :town_city, :min_bedrooms, :min_price, :max_price, :sort, :alerts_enabled)
  end
end
