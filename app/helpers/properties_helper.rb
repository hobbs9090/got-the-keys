module PropertiesHelper
  def small_image_for(property)
    image_name = property.hero_image_name

    if image_name.blank?
      property_image_small(class_name: 'property-card__image')
    else
      listing_image_tag(image_name, class_name: 'property-card__image', alt: property.headline)
    end
  end

  def medium_image_for(property)
    image_name = property.hero_image_name

    if image_name.blank?
      property_image_medium(class_name: 'property-hero__image')
    else
      listing_image_tag(image_name, class_name: 'property-hero__image', alt: property.headline)
    end
  end

  def format_bedrooms(property)
    if property.bedrooms == 0
      content_tag(:span, t(:studio_flat))
    else
      t("ui.properties.bedroom_count", count: property.bedrooms)
    end
  end

  def format_bathrooms(count)
    t("ui.properties.bathroom_count", count:)
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
    cues << t("ui.properties.trust_cues.brochure_ready") if property.public_documents.any?
    cues.uniq
  end

  def property_card_download_documents(property, limit: 2)
    property.public_documents.select(&:pdf?).first(limit)
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
    chips << t("ui.properties.filters.min_bedrooms_chip", count: filters[:min_bedrooms]) if filters[:min_bedrooms].present?
    chips << t(
      "ui.properties.filters.min_price_chip",
      price: number_to_currency(filters[:min_price], unit: '£', precision: 0)
    ) if filters[:min_price].present?
    chips << t(
      "ui.properties.filters.max_price_chip",
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

  def listing_state_badge_class(state)
    {
      "draft" => "badge badge--muted",
      "review_pending" => "badge badge--warning",
      "published" => "badge badge--success",
      "under_offer" => "badge badge--accent",
      "let_agreed" => "badge badge--accent",
      "sold" => "badge badge--neutral",
      "let" => "badge badge--neutral",
      "withdrawn" => "badge badge--danger"
    }.fetch(state.to_s, "badge")
  end

  def property_fact_rows(property)
    [
      [t("ui.properties.facts.tenure"), property.tenure],
      [t("ui.properties.facts.council_tax_band"), property.council_tax_band],
      [t("ui.properties.facts.furnishing"), property.sale_status == Property::SALE_STATUSES[:for_rent] ? property.furnishing : nil],
      [t("ui.properties.facts.year_built"), property.year_built],
      [t("ui.properties.facts.refurbished_year"), property.refurbished_year],
      [t("ui.properties.facts.available_from"), property.available_from.present? ? l(property.available_from, format: :long) : nil],
      [t("ui.properties.facts.parking"), property.parking],
      [t("ui.properties.facts.outdoor_space"), property.outdoor_space],
      [t("ui.properties.facts.floor_area"), property.floor_area_sq_ft.present? ? t("ui.properties.facts.floor_area_value", area: property.floor_area_sq_ft) : nil],
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

  private

  def listing_image_tag(image_name, class_name:, alt:)
    retina_name = listing_retina_image_name(image_name)

    if retina_name.present?
      pixel_density_image_tag(image_name, retina_source: retina_name, class: class_name, alt: alt)
    else
      tag.img(src: listing_image_source(image_name), class: class_name, alt: alt)
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
