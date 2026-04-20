module PropertiesHelper
  def property_type_select_options
    Property::PROPERTY_TYPES.map do |type|
      [I18n.t("ui.properties.editor.property_types.#{type.downcase}", default: type), type]
    end
  end

  def tenure_select_options
    Property::TENURE_OPTIONS.map do |value|
      key = value == "Shared Ownership" ? "shared_ownership" : value.parameterize.underscore
      [I18n.t("ui.properties.editor.tenure_options.#{key}", default: value), value]
    end
  end

  def small_image_for(property)
    image_name = property.hero_image_name

    if image_name.blank?
      property_image_small(class_name: 'property-card__image')
    else
      listing_image_tag(image_name, class_name: 'property-card__image', alt: property.headline, loading: "lazy", fetchpriority: "low")
    end
  end

  def medium_image_for(property)
    image_name = property.hero_image_name

    if image_name.blank?
      property_image_medium(class_name: 'property-hero__image')
    else
      listing_image_tag(image_name, class_name: 'property-hero__image', alt: property.headline, fetchpriority: "high")
    end
  end

  def format_bedrooms(property)
    if property.bedrooms == 0
      content_tag(:span, t(:studio_flat))
    else
      translate_count("ui.properties.bedroom_count", property.bedrooms)
    end
  end

  def format_bathrooms(count)
    translate_count("ui.properties.bathroom_count", count)
  end

  def format_price(property)
    number_to_currency(property.asking_price, :unit => "£", :precision => 0)
  end

  def format_renminbi(property)
    number_to_currency(
      property.asking_price * AppSettings.exchange_rate_gbp_to_cny,
      unit: '¥',
      precision: 0
    )
  end

  def property_card_classes(property)
    classes = ['property-card']
    classes << 'property-card--featured' if property.featured?
    classes << "property-card--#{property.listing_state.to_s.dasherize}" if property.listing_state.present?
    classes.join(' ')
  end

  def translated_sale_status(status)
    case status
    when Property::SALE_STATUSES[:for_sale]
      t("ui.properties.sale_statuses.for_sale")
    when Property::SALE_STATUSES[:for_rent]
      t("ui.properties.sale_statuses.for_rent")
    else
      status
    end
  end

  def property_sale_status_badge_class(status)
    case status
    when Property::SALE_STATUSES[:for_sale]
      "badge badge--accent"
    when Property::SALE_STATUSES[:for_rent]
      "badge badge--success"
    else
      "badge"
    end
  end

  def property_sale_status_options(include_all: false)
    options = []
    options << [t("ui.properties.filters.all_listings"), nil] if include_all
    options.concat(
      [
        [t("ui.properties.sale_statuses.for_sale"), Property::SALE_STATUSES[:for_sale]],
        [t("ui.properties.sale_statuses.for_rent"), Property::SALE_STATUSES[:for_rent]]
      ]
    )
    options
  end

  def property_sort_options
    Property::SORT_OPTIONS.map { |sort| [property_sort_label(sort), sort] }
  end

  def property_sort_label(sort)
    t("ui.properties.filters.sort_options.#{sort.presence || 'recommended'}")
  end

  def property_filter_price_label(bound, sale_status = nil)
    t(property_filter_price_translation_key(bound, sale_status))
  end

  def property_location_label(property)
    t("ui.properties.in_location", property_type: property.property_type, location: property.location_line)
  end

  def primary_branch_profile
    AppSettings.primary_branch_profile
  end

  def property_trust_cues(property, include_response_time: true)
    cues = []
    cues << t("ui.properties.trust_cues.recently_updated") if property.recently_updated?
    cues << t("ui.properties.trust_cues.available_now") if property.available_now?
    cues << primary_branch_profile.fetch(:response_time) if include_response_time
    cues.uniq
  end

  def property_card_download_documents(property, limit: 2)
    property.public_documents.select(&:pdf?).first(limit)
  end

  def property_card_document_label(document)
    return t("ui.property_documents.categories.brochure", default: "Brochure") if document.category.to_s == "brochure"

    document.title
  end

  def property_card_next_slot(property)
    preloaded_slots = instance_variable_defined?(:@next_available_slots_by_property_id) ? @next_available_slots_by_property_id : nil
    return preloaded_slots[property.id] if preloaded_slots&.key?(property.id)

    property.next_available_slots(limit: 1).first
  end

  def property_update_label(property)
    return t("ui.properties.update_labels.recently_updated") if property.recently_updated?
    return t("ui.properties.update_labels.stale") if property.stale_listing?

    t("ui.properties.update_labels.current")
  end

  def property_filter_chip_labels(filters)
    filters = filters.to_h.symbolize_keys
    chips = []
    chips << translated_sale_status(filters[:sale_status]) if filters[:sale_status].present?
    chips << t("ui.properties.filters.search_chip", query: filters[:q]) if filters[:q].present?
    chips << filters[:town_city] if filters[:town_city].present?
    chips << translate_count("ui.properties.filters.min_bedrooms_chip", filters[:min_bedrooms]) if filters[:min_bedrooms].present?
    chips << t(
      property_filter_price_translation_key(:min, filters[:sale_status], suffix: :chip),
      price: number_to_currency(filters[:min_price], unit: '£', precision: 0)
    ) if filters[:min_price].present?
    chips << t(
      property_filter_price_translation_key(:max, filters[:sale_status], suffix: :chip),
      price: number_to_currency(filters[:max_price], unit: '£', precision: 0)
    ) if filters[:max_price].present?

    sort = filters[:sort].presence
    chips << property_sort_label(sort) if sort.present? && sort != 'recommended'
    chips
  end

  def translated_listing_state(state)
    t("ui.properties.listing_states.#{state}", default: state.to_s.tr("_", " ").humanize)
  end

  def property_listing_state_options
    Property::LISTING_STATES.map { |state| [translated_listing_state(state), state] }
  end

  def property_listing_state_options_for_seller
    Property::SELLER_ALLOWED_LISTING_STATES.map { |state| [translated_listing_state(state), state] }
  end

  def admin_property_listing_form?(form_route_model)
    form_route_model.is_a?(Array) && form_route_model.first == :admin
  end

  def listing_state_badge_class(state)
    {
      "draft" => "badge badge--muted",
      "review_pending" => "badge badge--warning",
      "published" => "badge badge--success",
      "under_offer" => "badge badge--warning",
      "let_agreed" => "badge badge--warning",
      "sold" => "badge badge--neutral",
      "let" => "badge badge--neutral",
      "withdrawn" => "badge badge--danger"
    }.fetch(state.to_s, "badge")
  end

  def property_featured_badge_class
    "badge badge--neutral"
  end

  def property_fact_rows(property)
    [
      [t("ui.properties.facts.tenure"), property.tenure],
      [t("ui.properties.facts.council_tax_band"), property.council_tax_band],
      [t("ui.properties.facts.furnishing"), property.sale_status == Property::SALE_STATUSES[:for_rent] ? property.furnishing : nil],
      [t("ui.properties.facts.year_built"), property.year_built.present? ? display_number(property.year_built) : nil],
      [t("ui.properties.facts.refurbished_year"), property.refurbished_year.present? ? display_number(property.refurbished_year) : nil],
      [t("ui.properties.facts.available_from"), property.available_from.present? ? l(property.available_from, format: :long) : nil],
      [t("ui.properties.facts.parking"), property.parking],
      [t("ui.properties.facts.outdoor_space"), property.outdoor_space],
      [t("ui.properties.facts.floor_area"), property.floor_area_sq_ft.present? ? t("ui.properties.facts.floor_area_value", area: display_number(property.floor_area_sq_ft)) : nil],
      [t("ui.properties.facts.deposit"), property.deposit_amount.present? ? number_to_currency(property.deposit_amount, unit: "£", precision: 0) : nil],
      [t("ui.properties.facts.pets_allowed"), property.pets_allowed? ? t("ui.common.yes") : nil],
      [t("ui.properties.facts.service_charge"), property.service_charge_amount.present? ? number_to_currency(property.service_charge_amount, unit: "£", precision: 0) : nil],
      [t("ui.properties.facts.lease_length"), property.lease_length_years.present? ? t("ui.properties.facts.lease_length_value", years: property.lease_length_years) : nil]
    ].select { |_label, value| value.present? }
  end

  def property_document_category_options
    PropertyDocument::CATEGORIES.map { |category| [t("ui.property_documents.categories.#{category}", default: category.to_s.tr("_", " ").humanize), category] }
  end

  def property_document_visibility_options
    PropertyDocument::VISIBILITIES.map { |visibility| [t("ui.property_documents.visibilities.#{visibility}", default: visibility.humanize), visibility] }
  end

  def property_activity_action_label(action)
    t("ui.properties.activity_actions.#{action}", default: action.to_s.tr("_", " ").humanize)
  end

  def previewable_image_file?(file_name)
    extension = File.extname(file_name.to_s).downcase
    extension.in?(%w[.jpg .jpeg .png .webp .gif])
  end

  private

  def property_filter_price_translation_key(bound, sale_status, suffix: nil)
    normalized_bound = bound.to_s
    normalized_suffix = suffix.present? ? "_#{suffix}" : ""
    base_key =
      if sale_status == Property::SALE_STATUSES[:for_rent]
        "#{normalized_bound}_monthly_rental"
      else
        "#{normalized_bound}_price"
      end

    "ui.properties.filters.#{base_key}#{normalized_suffix}"
  end

  def listing_image_tag(image_name, class_name:, alt:, loading: nil, fetchpriority: nil)
    retina_name = listing_retina_image_name(image_name)
    html_options = image_options_with_intrinsic_dimensions(
      image_name,
      class: class_name,
      alt: alt,
      loading: loading,
      fetchpriority: fetchpriority
    ).compact

    if retina_name.present?
      pixel_density_image_tag(image_name, retina_source: retina_name, **html_options)
    else
      tag.img(src: listing_image_source(image_name), **html_options)
    end
  end

  def listing_image_source(image_name)
    path_to_image(image_name)
  rescue StandardError
    source = image_name.to_s
    return source if source.start_with?("/", "http://", "https://", "data:")

    "/#{ERB::Util.url_encode(source)}"
  end

  def listing_retina_image_name(image_name)
    source = image_name.to_s
    return if source.blank? || source.start_with?("/", "http://", "https://", "data:")

    extension = File.extname(source)
    return if extension.blank?

    retina_name = source.sub(/#{Regexp.escape(extension)}\z/i, "@2x#{extension}")
    retina_name if listing_asset_exists?(retina_name)
  end

  def listing_asset_exists?(image_name)
    return true if Rails.root.join("app/assets/images", image_name).exist?

    Rails.application.assets_manifest.assets.key?(image_name)
  end
end
