module CataloguePageBounds
  extend ActiveSupport::Concern

  private

  def redirect_if_page_out_of_range!(collection)
    return unless collection.respond_to?(:out_of_range?) && collection.out_of_range?
    return if collection.total_pages.zero?

    redirect_to url_for(params.permit!.merge(page: collection.total_pages)), status: :moved_permanently
  end
end
