class EnquiryMailer < ApplicationMailer
  def acknowledgement
    @enquiry = params.fetch(:enquiry)
    @property = @enquiry.property

    mail(
      to: @enquiry.customer_email,
      subject: "We received your enquiry about #{@property.address_line_1}"
    )
  end

  def internal_notification
    @enquiry = params.fetch(:enquiry)
    @property = @enquiry.property

    mail(
      to: internal_recipient,
      subject: "New #{@enquiry.display_source.downcase} for #{@property.address_line_1}"
    )
  end

  private

  def internal_recipient
    ENV.fetch("LEADS_INBOX_EMAIL", "sales@gotthekeys.com")
  end
end
