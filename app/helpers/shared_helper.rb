module SharedHelper

  def hero_1_image
    image_tag("hero_1.jpg")
  end

  def hero_2_image
    image_tag("hero_2.jpg")
  end

  def hero_3_image
    image_tag("hero_3.jpg")
  end

  def welcome_image
    image_tag("placeholder_beach@2x.jpg")
  end

  def world_image
    image_tag("placeholder_world@2x.jpg")
  end

  def face_image
    image_tag("placeholder_face@2x.jpg")
  end

  def warren_image
    image_tag("warren_face@2x.jpg")
  end

  def steven_image
    image_tag("steven_face@2x.jpg")
  end

  def square_image
    image_tag("placeholder_square.jpg")
  end

  def under_construction_image
    image_tag("under_construction.svg", :size => '80x80', :class => 'under_construction')
  end

  def property_image_small
    image_tag("placeholder_beach@2x.jpg", :size => '160')
  end

  def property_image_medium
    image_tag("placeholder_beach@2x.jpg", :size => '250')
  end

  def format_time(time)
    time.strftime("%B %d %Y, %H:%M")
  end

  def format_date(time)
    time.strftime("%d %B, %Y")
  end

  def get_statistics
    @total_number_users = User.count
    @total_number_en_users = User.where(:language => 'en').count
    @total_number_zh_users = User.where(:language => 'zh').count
    @total_portfolio_on_books = Property.sum(:asking_price)
    @total_properties = Property.count
    @total_for_sale = Property.where(:sale_status => 'For Sale').count
    @total_for_rent = Property.where(:sale_status => 'For Rent').count
    @total_0_bedrooms = Property.where(:bedrooms => '0').count
    @total_1_bedrooms = Property.where(:bedrooms => '1').count
    @total_2_bedrooms = Property.where(:bedrooms => '2').count
    @total_3_bedrooms = Property.where(:bedrooms => '3').count
    @total_4_bedrooms = Property.where(:bedrooms => '4').count
    @total_5_bedrooms = Property.where(:bedrooms => '5').count
    @total_6_bedrooms = Property.where(:bedrooms => '> 5').count
  end

  def format_name(user)
    user.first_name.capitalize + ' ' + user.last_name.capitalize
  end

end