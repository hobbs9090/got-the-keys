module PropertiesHelper
  def cache_key_for_properties_total
    max_updated_at = Property.maximum(:updated_at)
    "properties/all-#{max_updated_at}"
  end

  def small_image_for(property)
    if property.image_file_name.blank?
      property_image_small(class_name: 'property-card__image')
    else
      image_tag(property.image_file_name, class: 'property-card__image', alt: property.headline)
    end
  end

  def medium_image_for(property)
    if property.image_file_name.blank?
      property_image_medium(class_name: 'property-hero__image')
    else
      image_tag(property.image_file_name, class: 'property-hero__image', alt: property.headline)
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
end
