class ViewingTimesController < ApplicationController
  include PropertyScoped

  before_action :set_property
  before_action :authenticate_user!
  before_action :authorize_property_owner!, only: [:new, :create]

  def index
    @viewing_times = @property.viewing_times
  end

  def new
    @viewing_time = @property.viewing_times.new
  end

  def create
    @viewing_time = @property.viewing_times.new(viewing_time_params)
    if @viewing_time.save
      redirect_to property_viewing_times_path(@property),
                  notice: t("ui.legacy.viewing_times_updated_notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def viewing_time_params
    params.require(:viewing_time).permit(:start_time, :end_time)
  end
end
