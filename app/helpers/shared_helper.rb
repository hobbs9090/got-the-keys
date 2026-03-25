module SharedHelper
  def hero_1_image
    image_tag('hero_1.jpg')
  end

  def hero_2_image
    image_tag('hero_2.jpg')
  end

  def hero_3_image
    image_tag('hero_3.jpg')
  end

  def welcome_image_1
    image_tag('welcome_1.jpg')
  end

  def welcome_image_2
    image_tag('welcome_2.jpg')
  end

  def world_image
    image_tag('placeholder_world@2x.jpg')
  end

  def face_image
    image_tag('placeholder_face@2x.jpg')
  end

  def steven_image
    image_tag('steven_face@2x.jpg')
  end

  def square_image
    image_tag('placeholder_square.jpg')
  end

  def under_construction_image
    image_tag('under_construction.svg', size: '80x80', class: 'under_construction')
  end

  def property_image_small
    image_tag('placeholder_beach@2x.jpg', size: '160')
  end

  def property_image_medium
    image_tag('placeholder_beach@2x.jpg', size: '250')
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
