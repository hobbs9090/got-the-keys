class SavedSearchesController < ApplicationController
  def create
    @saved_search = SavedSearch.new(saved_search_params)

    if @saved_search.save
      matches = @saved_search.matching_properties_count
      redirect_to properties_path(@saved_search.filter_params), notice: "Saved search created for #{matches} matching #{'listing'.pluralize(matches)}."
    else
      redirect_to properties_path(@saved_search.filter_params), alert: @saved_search.errors.full_messages.to_sentence
    end
  end

  private

  def saved_search_params
    params.require(:saved_search).permit(:email, :locale, :sale_status, :search_query, :town_city, :min_bedrooms, :min_price, :max_price, :sort, :alerts_enabled)
  end
end
