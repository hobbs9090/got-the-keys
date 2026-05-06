class SavedSearchesController < ApplicationController
  include SavedSearchCatalogueRedirects

  before_action :require_saved_search_identity!

  def create
    form = saved_search_form_params
    redirect_scope = catalogue_scope_from_saved_search_form
    @saved_search = saved_search_owner.saved_searches.build(saved_search_attributes_from(form, redirect_scope))

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
    @removed_saved_search = search
    search.destroy!
    remaining = saved_search_owner.saved_searches.count

    respond_to do |format|
      format.turbo_stream do
        if params[:admin_saved_filter_removal].present?
          @remaining_saved_searches_count = remaining
          render :destroy
        else
          redirect_to catalogue_redirect_path_for(filter_params, scope), notice: t("ui.saved_searches.destroyed")
        end
      end
      format.html do
        redirect_to catalogue_redirect_path_for(filter_params, scope), notice: t("ui.saved_searches.destroyed")
      end
    end
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
      language: I18n.default_locale.to_s,
      terms_of_service: true,
      admin_provisioned: true,
      password: generated_password,
      password_confirmation: generated_password
    )
  rescue ActiveRecord::RecordNotUnique
    User.find_by(email: current_admin.email)
  end

  def saved_search_form_params
    params.require(:saved_search).permit(
      :locale, :sale_status, :search_query, :town, :town_city, :min_bedrooms,
      :min_price, :max_price, :sort, :alerts_enabled, :catalogue_scope
    )
  end

  def saved_search_attributes_from(form, scope)
    filters = parsed_catalogue_filters_for(form, scope)

    {
      locale: form[:locale],
      sale_status: filters[:sale_status],
      search_query: filters[:q],
      town_city: filters[:town_city],
      min_bedrooms: filters[:min_bedrooms],
      min_price: filters[:min_price],
      max_price: filters[:max_price],
      sort: filters[:sort],
      alerts_enabled: form[:alerts_enabled]
    }
  end

  def parsed_catalogue_filters_for(form, scope)
    raw_filters = {
      q: form[:search_query],
      sale_status: form[:sale_status],
      town: form[:town],
      town_city: form[:town_city],
      min_bedrooms: form[:min_bedrooms],
      min_price: form[:min_price],
      max_price: form[:max_price],
      sort: form[:sort]
    }

    PropertyCatalogueQuery.new(
      params: raw_filters,
      town_scope: town_scope_for_saved_search(scope),
      default_filters: default_filters_for_saved_search(scope)
    ).call.filters
  end

  def default_filters_for_saved_search(scope)
    case scope.to_s
    when "for_rent"
      { sale_status: Property::SALE_STATUSES[:for_rent] }
    when "for_sale"
      { sale_status: Property::SALE_STATUSES[:for_sale] }
    else
      {}
    end
  end

  def town_scope_for_saved_search(scope)
    case scope.to_s
    when "for_rent"
      Property.for_rent
    when "for_sale"
      Property.for_sale
    else
      Property.publicly_visible
    end
  end
end
