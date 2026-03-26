require "rails_helper"

RSpec.describe EnquiryNotificationJob do
  let(:enquiry) { FactoryBot.create(:enquiry) }

  it "delegates delivery to EnquiryNotifier" do
    notifier = instance_double(EnquiryNotifier, deliver: true)

    allow(EnquiryNotifier).to receive(:new).with(enquiry, event_type: "created").and_return(notifier)

    described_class.perform_now(enquiry.id, "created")

    expect(EnquiryNotifier).to have_received(:new).with(enquiry, event_type: "created")
    expect(notifier).to have_received(:deliver)
  end

  it "discards missing enquiries cleanly" do
    expect do
      described_class.perform_now(-1, "created")
    end.not_to raise_error
  end
end
