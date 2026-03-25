module SharedHelper
  def hero_1_image
    pixel_density_image_tag('hero_1.jpg', retina_source: 'hero_1@2x.jpg')
  end

  def hero_2_image
    pixel_density_image_tag('hero_2.jpg', retina_source: 'hero_2@2x.jpg')
  end

  def hero_3_image
    pixel_density_image_tag('hero_3.jpg', retina_source: 'hero_3@2x.jpg')
  end

  def welcome_image_1
    image_tag('welcome_1.jpg')
  end

  def welcome_image_2
    image_tag('welcome_2.jpg')
  end

  def world_image
    pixel_density_image_tag('placeholder_world.jpg', retina_source: 'placeholder_world@2x.jpg')
  end

  def face_image
    pixel_density_image_tag('placeholder_face.jpg', retina_source: 'placeholder_face@2x.jpg')
  end

  def steven_image
    pixel_density_image_tag('steven_face.jpg', retina_source: 'steven_face@2x.jpg')
  end

  def square_image
    image_tag('placeholder_square.jpg')
  end

  def under_construction_image
    image_tag('under_construction.svg', size: '80x80', class: 'under_construction')
  end

  def property_image_small(class_name: nil)
    image_tag('property_placeholder_listing.svg', size: '160', class: class_name, alt: 'Property placeholder image')
  end

  def property_image_medium(class_name: nil)
    image_tag('property_placeholder_listing.svg', size: '250', class: class_name, alt: 'Property placeholder image')
  end

  def format_time(time)
    time.strftime('%B %d %Y, %H:%M')
  end

  def format_date(time)
    time.strftime('%d %B, %Y')
  end

  def format_name(user)
    [user.first_name, user.last_name].map(&:capitalize).join(' ')
  end
end
