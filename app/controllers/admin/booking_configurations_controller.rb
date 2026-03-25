class Admin::BookingConfigurationsController < Admin::BaseController
  def show
    @booking_configuration = booking_configuration
  end

  def update
    if booking_configuration.update(booking_configuration_params)
      redirect_to admin_booking_configuration_path, notice: "Booking rules updated."
    else
      @booking_configuration = booking_configuration
      render :show, status: :unprocessable_entity
    end
  end

  private

  def booking_configuration_params
    params.require(:booking_configuration).permit(:slot_duration_minutes, :lead_time_hours, :buffer_minutes, :office_opens_at, :office_closes_at, open_weekdays: [])
  end
end
