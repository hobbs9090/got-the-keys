class EnquiryMailer < ApplicationMailer
  def acknowledgement
    @enquiry = params.fetch(:enquiry)
    @property = @enquiry.property

    mail(
      to: @enquiry.customer_email,
      subject: I18n.t("ui.enquiries.mailer.acknowledgement_subject", address: @property.address_line_1)
    )
  end

  def internal_notification
    @enquiry = params.fetch(:enquiry)
    @property = @enquiry.property

    mail(
      to: internal_recipient,
      subject: I18n.t("ui.enquiries.mailer.internal_subject", source: @enquiry.display_source.downcase, address: @property.address_line_1)
    )
  end

  private

  def internal_recipient
    ENV.fetch("LEADS_INBOX_EMAIL", "sales@gotthekeys.com")
  end
end
