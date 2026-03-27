class FloorPlansController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :authenticate_user!, except: [:index]
  before_action :authorize_property_owner!, except: [:index]
  before_action :set_floor_plan, only: [:update, :destroy]

  def index
    @floor_plans = @property.floor_plans.ordered
    @new_floor_plan = @property.floor_plans.new(position: next_position)
  end

  def new
    redirect_to property_floor_plans_path(@property)
  end

  def create
    @floor_plans = @property.floor_plans.ordered
    @new_floor_plan = @property.floor_plans.new(floor_plan_params)

    if @new_floor_plan.save
      redirect_to property_floor_plans_path(@property), notice: t("ui.floor_plans.flash.added")
    else
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @floor_plans = @property.floor_plans.ordered
    @new_floor_plan = @property.floor_plans.new(position: next_position)
    @edited_floor_plan = @floor_plan

    if @floor_plan.update(floor_plan_params)
      redirect_to property_floor_plans_path(@property), notice: t("ui.floor_plans.flash.updated")
    else
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @floor_plan.destroy
    redirect_to property_floor_plans_path(@property), notice: t("ui.floor_plans.flash.removed")
  end

  private

  def set_floor_plan
    @floor_plan = @property.floor_plans.find(params[:id])
  end

  def floor_plan_params
    params.require(:floor_plan).permit(:floor_plans, :label, :position)
  end

  def next_position
    @property.floor_plans.maximum(:position).to_i + 1
  end
end
