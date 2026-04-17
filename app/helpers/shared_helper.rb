module SharedHelper
  def hero_1_image(loading: nil, fetchpriority: nil)
    pixel_density_image_tag('hero_1.webp', retina_source: 'hero_1@2x.webp', alt: "", loading:, fetchpriority:)
  end

  def hero_2_image(loading: nil, fetchpriority: nil)
    pixel_density_image_tag('hero_2.webp', retina_source: 'hero_2@2x.webp', alt: "", loading:, fetchpriority:)
  end

  def hero_3_image(loading: nil, fetchpriority: nil)
    pixel_density_image_tag('hero_3.webp', retina_source: 'hero_3@2x.webp', alt: "", loading:, fetchpriority:)
  end

  def hero_4_image(loading: nil, fetchpriority: nil)
    pixel_density_image_tag('hero_4.webp', retina_source: 'hero_4@2x.webp', alt: "", loading:, fetchpriority:)
  end

  def hero_5_image(loading: nil, fetchpriority: nil)
    pixel_density_image_tag('hero_5.webp', retina_source: 'hero_5@2x.webp', alt: "", loading:, fetchpriority:)
  end

  def world_image
    image_tag('placeholder_world.svg', alt: "")
  end

  def under_construction_image
    image_tag('under_construction.svg', size: '80x80', class: 'under_construction', alt: "")
  end

  def property_image_small(class_name: nil)
    image_tag(
      'properties/property_placeholder_listing.svg',
      size: '160',
      class: class_name,
      alt: t("ui.shared.property_placeholder_alt")
    )
  end

  def property_image_medium(class_name: nil)
    image_tag(
      'properties/property_placeholder_listing.svg',
      size: '250',
      class: class_name,
      alt: t("ui.shared.property_placeholder_alt")
    )
  end

  def format_time(time)
    I18n.l(time, format: :shared_time)
  end

  def format_date(time)
    I18n.l(time.to_date, format: :shared_date)
  end

  def format_name(user)
    [user.first_name, user.last_name].map(&:capitalize).join(' ')
  end
end
