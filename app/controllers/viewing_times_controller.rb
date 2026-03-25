class ViewingTimesController < ApplicationController

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
                  notice: 'Available viewing times have been updated!'
    else
      render :new
    end
  end

  private

  def viewing_time_params
    params.require(:viewing_time).permit(:start_time, :end_time)
  end

  def set_property
    @property = Property.find(params[:property_id])
  end

  def authorize_property_owner!
    return if @property.user == current_user

    redirect_to root_path, alert: t(:not_authorised)
  end

end
