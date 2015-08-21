class MembersController < ApplicationController

  before_action :authenticate_admin!

  def index
    @users = User.page(params[:page]).per(10)
    @total_number_users = User.user_count
  end

end