class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: :show

  def index
    @users = User.includes(:properties).order(:last_name, :first_name)
  end

  def show
    @appointments = Appointment.joins(:property).where(properties: { user_id: @user.id }).recent_first.limit(20)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
