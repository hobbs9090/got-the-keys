class AppointmentNotificationJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(appointment_id, event_type)
    appointment = Appointment.find(appointment_id)
    AppointmentNotifier.new(appointment, event_type: event_type).deliver
  end
end
