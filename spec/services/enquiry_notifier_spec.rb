require "rails_helper"

RSpec.describe EnquiryNotifier do
  let(:enquiry) do
    FactoryBot.create(
      :enquiry,
      customer_name: "Nina Hall",
      customer_email: "nina@example.com",
      customer_phone: "07700 900333"
    )
  end

  before do
    enquiry
    NotificationLog.delete_all
    ActionMailer::Base.deliveries.clear
  end

  it "delivers the acknowledgement and internal notification in test" do
    expect do
      described_class.new(enquiry, event_type: "created").deliver
    end.to change(NotificationLog, :count).by(2)

    expect(NotificationLog.pluck(:status)).to eq(%w[sent sent])
    expect(NotificationLog.pluck(:event_type)).to contain_exactly("enquiry_acknowledgement", "enquiry_internal_notification")
    expect(ActionMailer::Base.deliveries.map(&:subject)).to include(
      "We received your enquiry about #{enquiry.property.address_line_1}",
      "New #{enquiry.display_source.downcase} for #{enquiry.property.address_line_1}"
    )
  end

  it "skips the acknowledgement when the customer has no email address" do
    enquiry.update!(customer_email: nil)

    expect do
      described_class.new(enquiry, event_type: "created").deliver
    end.to change(NotificationLog, :count).by(2)

    acknowledgement_log = NotificationLog.find_by(event_type: "enquiry_acknowledgement")
    internal_log = NotificationLog.find_by(event_type: "enquiry_internal_notification")

    expect(acknowledgement_log.status).to eq("skipped")
    expect(internal_log.status).to eq("sent")
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end
end
