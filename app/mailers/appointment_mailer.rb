class AppointmentMailer < ApplicationMailer
  def status_update
    @appointment = params.fetch(:appointment)
    @event_type = params.fetch(:event_type)
    @property = @appointment.property
    @access_token = params[:access_token].presence || @appointment.issue_access_token!
    @appointment_url = appointment_url(@appointment, token: @access_token)
    attach_calendar_event

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
      when "reminder"
        "reminder"
      when "no_show"
        "marked_as_missed"
      else
        "updated"
      end

    I18n.t(
      "ui.appointment_mailer.subject",
      action: I18n.t("ui.appointment_mailer.actions.#{action_key}", default: action_key.tr("_", " ")),
      reference: @appointment.public_reference
    )
  end

  def attach_calendar_event
    attachments["gotthekeys-viewing-#{@appointment.public_reference}.ics"] = {
      mime_type: "text/calendar",
      content: calendar_payload
    }
  end

  def calendar_payload
    starts_at = @appointment.scheduled_at.utc.strftime("%Y%m%dT%H%M%SZ")
    ends_at = @appointment.end_at.utc.strftime("%Y%m%dT%H%M%SZ")

    <<~ICS
      BEGIN:VCALENDAR
      VERSION:2.0
      PRODID:-//GotTheKeys//Viewing//EN
      CALSCALE:GREGORIAN
      BEGIN:VEVENT
      UID:#{@appointment.public_reference}@gotthekeys
      DTSTAMP:#{Time.current.utc.strftime("%Y%m%dT%H%M%SZ")}
      DTSTART:#{starts_at}
      DTEND:#{ends_at}
      SUMMARY:GotTheKeys viewing at #{@property.address_line_1}
      DESCRIPTION:Reference #{@appointment.public_reference}
      LOCATION:#{[@property.address_line_1, @property.town_city, @property.postcode].compact.join(", ")}
      END:VEVENT
      END:VCALENDAR
    ICS
  end
end
