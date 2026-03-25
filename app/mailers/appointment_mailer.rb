class AppointmentMailer < ApplicationMailer
  def status_update
    @appointment = params.fetch(:appointment)
    @event_type = params.fetch(:event_type)
    @property = @appointment.property

    mail(
      to: @appointment.customer_email,
      subject: subject_for(@event_type)
    )
  end

  private

  def subject_for(event_type)
    action =
      case event_type
      when "created"
        "request received"
      when "confirmed"
        "confirmed"
      when "cancelled"
        "cancelled"
      when "completed"
        "completed"
      when "no_show"
        "marked as missed"
      else
        "updated"
      end

    "GotTheKeys viewing #{action}: #{@appointment.public_reference}"
  end
end
