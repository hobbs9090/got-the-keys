module SavedSearchCatalogueRedirects
  extend ActiveSupport::Concern

  private

  ALLOWED_CATALOGUE_SCOPES = %w[properties searches for_rent for_sale].freeze

  def catalogue_redirect_path_for(filter_params, scope)
    fp = filter_params.symbolize_keys
    case scope.to_s
    when "for_rent"
      for_rent_index_path(fp)
    when "for_sale"
      for_sale_index_path(fp)
    when "searches"
      searches_path(fp)
    else
      properties_path(fp)
    end
  end

  def catalogue_scope_from_saved_search_form
    raw = params.dig(:saved_search, :catalogue_scope).to_s
    raw.presence_in(ALLOWED_CATALOGUE_SCOPES) || "properties"
  end

  def catalogue_scope_for_destroy(saved_search)
    case saved_search.sale_status
    when Property::SALE_STATUSES[:for_rent]
      "for_rent"
    when Property::SALE_STATUSES[:for_sale]
      "for_sale"
    else
      "properties"
    end
  end
end
