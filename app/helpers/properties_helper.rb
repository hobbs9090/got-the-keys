module PropertiesHelper
  def cache_key_for_properties_total
    max_updated_at = Property.maximum(:updated_at)
    "properties/all-#{max_updated_at}"
  end

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
    {
      "draft" => "Draft",
      "review_pending" => "Review pending",
      "published" => "Published",
      "under_offer" => "Under offer",
      "let_agreed" => "Let agreed",
      "sold" => "Sold",
      "let" => "Let",
      "withdrawn" => "Withdrawn"
    }.fetch(state.to_s, state.to_s.tr("_", " ").humanize)
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
      ["Tenure", property.tenure],
      ["Council tax band", property.council_tax_band],
      ["Furnishing", property.furnishing],
      ["Available from", property.available_from.present? ? l(property.available_from, format: :long) : nil],
      ["Parking", property.parking],
      ["Outdoor space", property.outdoor_space],
      ["EPC rating", property.epc_rating],
      ["Floor area", property.floor_area_sq_ft.present? ? "#{property.floor_area_sq_ft} sq ft" : nil],
      ["Deposit", property.deposit_amount.present? ? number_to_currency(property.deposit_amount, unit: "£", precision: 0) : nil],
      ["Pets allowed", property.pets_allowed? ? "Yes" : nil],
      ["Service charge", property.service_charge_amount.present? ? number_to_currency(property.service_charge_amount, unit: "£", precision: 0) : nil],
      ["Lease length", property.lease_length_years.present? ? "#{property.lease_length_years} years" : nil]
    ].select { |_label, value| value.present? }
  end

  private

  def listing_image_tag(image_name, class_name:, alt:)
    tag.img(src: listing_image_source(image_name), class: class_name, alt: alt)
  end

  def listing_image_source(image_name)
    path_to_image(image_name)
  rescue StandardError
    source = image_name.to_s
    return source if source.start_with?("/", "http://", "https://", "data:")

    "/#{ERB::Util.url_encode(source)}"
  end
end
