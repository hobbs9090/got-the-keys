class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: :show

  def index
    @query = params[:q].to_s.squish
    @users = filtered_users.order(:last_name, :first_name)
  end

  def show
    @properties = @user.properties.order(updated_at: :desc)
    @appointments = Appointment.joins(:property).where(properties: { user_id: @user.id }).recent_first.limit(20)
  end

  private

  def filtered_users
    scope = User.includes(:properties)
    return scope if @query.blank?

    @query.split.each do |term|
      pattern = "%#{User.sanitize_sql_like(term.downcase)}%"

      scope = scope.where(<<~SQL.squish, pattern:)
        LOWER(users.first_name) LIKE :pattern
        OR LOWER(users.last_name) LIKE :pattern
        OR LOWER(users.email) LIKE :pattern
        OR LOWER(users.mobile_number) LIKE :pattern
        OR LOWER(COALESCE(users.first_name, '') || ' ' || COALESCE(users.last_name, '')) LIKE :pattern
      SQL
    end

    scope
  end

  def set_user
    @user = User.find(params[:id])
  end
end
