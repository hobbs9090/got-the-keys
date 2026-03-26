class EnquiryNotifier
  def initialize(enquiry, event_type:)
    @enquiry = enquiry
    @event_type = event_type
  end

  def deliver
    deliver_acknowledgement
    deliver_internal_notification
  end

  private

  attr_reader :enquiry, :event_type

  def deliver_acknowledgement
    if enquiry.customer_email.blank?
      log_notification(
        status: "skipped",
        event_name: "enquiry_acknowledgement",
        recipient_email: nil,
        subject: "Skipped acknowledgement for #{enquiry.lead_reference}",
        body_preview: nil,
        error_message: "Customer email is blank."
      )
      return
    end

    deliver_mail(
      event_name: "enquiry_acknowledgement",
      recipient_email: enquiry.customer_email,
      mail: EnquiryMailer.with(enquiry:).acknowledgement
    )
  end

  def deliver_internal_notification
    mail = EnquiryMailer.with(enquiry:).internal_notification

    deliver_mail(
      event_name: "enquiry_internal_notification",
      recipient_email: Array(mail.to).first,
      mail:
    )
  end

  def deliver_mail(event_name:, recipient_email:, mail:)
    preview = mail.body.encoded.to_s.truncate(750)

    if delivery_configured?
      mail.deliver_now
      log_notification(status: "sent", event_name:, recipient_email:, subject: mail.subject, body_preview: preview)
    else
      log_notification(
        status: "skipped",
        event_name:,
        recipient_email:,
        subject: mail.subject,
        body_preview: preview,
        error_message: "SMTP is not configured for this environment."
      )
    end
  rescue StandardError => error
    log_notification(
      status: "failed",
      event_name:,
      recipient_email:,
      subject: mail.subject,
      body_preview: nil,
      error_message: "#{error.class}: #{error.message}"
    )
  end

  def delivery_configured?
    return true if Rails.env.development? || Rails.env.test?

    ENV["SMTP_ADDRESS"].present?
  end

  def log_notification(status:, event_name:, recipient_email:, subject:, body_preview:, error_message: nil)
    NotificationLog.create!(
      enquiry:,
      recipient_email:,
      subject:,
      body_preview:,
      event_type: event_name,
      status:,
      error_message:,
      metadata: {
        pipeline: "enquiry",
        source_event: event_type,
        lead_reference: enquiry.lead_reference,
        property_id: enquiry.property_id
      }
    )
  end
end
