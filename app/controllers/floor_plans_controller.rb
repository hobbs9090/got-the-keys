class FloorPlansController < ApplicationController
  include PropertyScoped

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
end
