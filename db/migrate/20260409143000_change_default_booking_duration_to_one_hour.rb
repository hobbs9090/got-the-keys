class ChangeDefaultBookingDurationToOneHour < ActiveRecord::Migration[8.1]
  class MigrationBookingConfiguration < ApplicationRecord
    self.table_name = "booking_configurations"
  end

  def up
    change_column_default :booking_configurations, :slot_duration_minutes, from: 45, to: 60
    change_column_default :appointments, :duration_minutes, from: 45, to: 60

    MigrationBookingConfiguration.where(slot_duration_minutes: 45).update_all(slot_duration_minutes: 60)
  end

  def down
    change_column_default :booking_configurations, :slot_duration_minutes, from: 60, to: 45
    change_column_default :appointments, :duration_minutes, from: 60, to: 45

    MigrationBookingConfiguration.where(slot_duration_minutes: 60).update_all(slot_duration_minutes: 45)
  end
end
