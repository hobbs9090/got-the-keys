class AddBookingWindowDaysToBookingConfigurations < ActiveRecord::Migration[8.0]
  def change
    add_column :booking_configurations, :booking_window_days, :integer, null: false, default: 21
  end
end
