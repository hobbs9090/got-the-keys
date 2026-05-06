class AppointmentNotifier
  def initialize(appointment, event_type:, access_token: nil)
    @appointment = appointment
    @event_type = event_type
    @access_token = access_token.presence || appointment.issue_access_token!
  end

  def deliver
    mail = appointment_mailer.status_update
    preview = mail.body.encoded.to_s.truncate(750)

    if delivery_configured?
      mail.deliver_now
      log_notification(status: "sent", body_preview: preview)
    else
      log_notification(
        status: "skipped",
        body_preview: preview,
        error_message: "SMTP is not configured for this environment."
      )
    end
  rescue StandardError => error
    log_notification(
      status: "failed",
      body_preview: nil,
      error_message: "#{error.class}: #{error.message}"
    )
  end

  private

  attr_reader :appointment, :event_type, :access_token

  def delivery_configured?
    return true if Rails.env.development? || Rails.env.test?

    ENV["SMTP_ADDRESS"].present?
  end

  def log_notification(status:, body_preview:, error_message: nil)
    NotificationLog.create!(
      appointment:,
      recipient_email: appointment.customer_email,
      subject: appointment_mailer.status_update.subject,
      body_preview:,
      event_type:,
      status:,
      error_message:,
      metadata: {
        appointment_reference: appointment.public_reference,
        property_id: appointment.property_id
      }
    )
  end

  def appointment_mailer
    AppointmentMailer.with(appointment:, event_type:, access_token:)
  end
end
