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
      pluralize(property.bedrooms, t('bedroom'))
    end
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

  def property_sort_label(sort)
    case sort
    when 'price_low'
      'Price: low to high'
    when 'price_high'
      'Price: high to low'
    when 'bedrooms_high'
      'Bedrooms first'
    when 'newest'
      'Newest first'
    else
      'Recommended'
    end
  end

  def property_filter_chip_labels(filters)
    filters = filters.to_h.symbolize_keys
    chips = []
    chips << filters[:sale_status] if filters[:sale_status].present?
    chips << "Search: #{filters[:q]}" if filters[:q].present?
    chips << filters[:town_city] if filters[:town_city].present?
    chips << "#{filters[:min_bedrooms]}+ bedrooms" if filters[:min_bedrooms].present?
    chips << "From #{number_to_currency(filters[:min_price], unit: '£', precision: 0)}" if filters[:min_price].present?
    chips << "Up to #{number_to_currency(filters[:max_price], unit: '£', precision: 0)}" if filters[:max_price].present?

    sort = filters[:sort].presence
    chips << property_sort_label(sort) if sort.present? && sort != 'recommended'
    chips
  end

end
