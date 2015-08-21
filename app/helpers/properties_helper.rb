module PropertiesHelper

  def cache_key_for_properties_total
    max_updated_at = Properties.maximum(:updated_at)
    "properties/all-#{max_updated_at}"
  end

  def small_image_for(property)
    if property.image_file_name.blank?
      property_image_small
    else
      image_tag(property.image_file_name)
    end
  end

  def medium_image_for(property)
    if property.image_file_name.blank?
      property_image_medium
    else
      image_tag(property.image_file_name)
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
    number_to_currency(property.asking_price * EXCHANGE_RATE, :unit => "¥", :precision => 0)
  end

end
