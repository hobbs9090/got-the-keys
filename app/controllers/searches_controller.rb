class SearchesController < ApplicationController

  def index
    @properties = Property.search_for_sale(params[:q]).page(params[:page])
    @number_search_results = Property.search_for_sale(params[:q])
  end

  # TODO need to use this action in 'For Sale' search
  def search_for_sale
    @properties = Property.search_for_sale(params[:q]).page(params[:page])
  end

end
