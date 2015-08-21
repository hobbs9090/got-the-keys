class StatisticsController < ApplicationController

  before_action :authenticate_admin!

  def index
    @total_number_users = User.user_count
    @total_number_en_users = User.total_number_en_users
    @total_number_zh_users = User.total_number_zh_users
    @total_portfolio_on_books = Property.total_portfolio_value
    @total_properties = Property.count
    @total_for_sale = Property.for_sale_total
    @total_for_rent = Property.for_rent_total
    @total_0_bedrooms = Property.total_0_bedrooms
    @total_1_bedrooms = Property.total_1_bedrooms
    @total_2_bedrooms = Property.total_2_bedrooms
    @total_3_bedrooms = Property.total_3_bedrooms
    @total_4_bedrooms = Property.total_4_bedrooms
    @total_5_bedrooms = Property.total_5_bedrooms
    @total_6_plus_bedrooms = Property.total_6_plus_bedrooms
    @active_users_today = User.active_today
    @users_added_today = User.added_today
    @properties_added_today = Property.added_today
  end

end
