module CataloguePageBounds
  extend ActiveSupport::Concern

  private

  CATALOGUE_FILTER_PARAMS = %i[q sale_status min_bedrooms min_price max_price town_city town sort].freeze

  def redirect_if_page_out_of_range!(collection)
    return unless collection.respond_to?(:out_of_range?) && collection.out_of_range?
    return if collection.total_pages.zero?

    safe_params = params.permit(*CATALOGUE_FILTER_PARAMS).merge(page: collection.total_pages)
    redirect_to url_for(safe_params), status: :moved_permanently
  end
end
