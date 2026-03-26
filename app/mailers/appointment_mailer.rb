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
    action_key =
      case event_type
      when "created"
        "request_received"
      when "confirmed"
        "confirmed"
      when "cancelled"
        "cancelled"
      when "completed"
        "completed"
      when "no_show"
        "marked_as_missed"
      else
        "updated"
      end

    I18n.t(
      "ui.appointment_mailer.subject",
      action: I18n.t("ui.appointment_mailer.actions.#{action_key}"),
      reference: @appointment.public_reference
    )
  end
end
