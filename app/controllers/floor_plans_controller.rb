class FloorPlansController < ApplicationController

  before_action :set_property
  before_action :authenticate_user!, only: [:new]
  before_action :authorize_property_owner!, only: [:new]

  def index
    @floor_plans = @property.floor_plans
  end

  def new
    @floor_plan = @property.floor_plans.new
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def authorize_property_owner!
    return if @property.user == current_user

    redirect_to root_path, alert: t(:not_authorised)
  end

end
