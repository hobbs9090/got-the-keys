class FloorPlansController < ApplicationController

  before_action :set_property

  def index
    @floor_plans = @property.floor_plans
  end

  def show
    @property = Property.find(params[:id])
  end

  def new
    @floor_plan = @property.floor_plans.new
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

end
