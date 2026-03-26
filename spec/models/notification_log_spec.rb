require "rails_helper"

RSpec.describe NotificationLog do
  let(:appointment) { FactoryBot.create(:appointment, customer_name: "Asha Patel", customer_email: "asha@example.com", customer_phone: "07700 900222") }

  before do
    appointment
    described_class.delete_all
  end

  it "validates the allowed statuses" do
    log = FactoryBot.build(:notification_log, appointment:, subject: "Status update", event_type: "confirmed", status: "queued")

    expect(log).not_to be_valid
    expect(log.errors[:status]).to include("is not included in the list")
  end

  it "allows logs without an appointment association" do
    log = FactoryBot.build(:notification_log, :without_appointment, subject: "General notice", event_type: "export", status: "sent")

    expect(log).to be_valid
  end

  it "allows logs tied to an enquiry" do
    enquiry = FactoryBot.create(:enquiry)
    log = FactoryBot.build(:notification_log, appointment: nil, enquiry:, subject: "Lead received", event_type: "enquiry_acknowledgement", status: "sent")

    expect(log).to be_valid
  end

  it "orders logs with the newest entry first" do
    older_log = FactoryBot.create(
      :notification_log,
      appointment:,
      subject: "Older update",
      event_type: "confirmed",
      status: "sent",
      created_at: 2.days.ago,
      updated_at: 2.days.ago
    )
    newer_log = FactoryBot.create(
      :notification_log,
      :failed,
      appointment:,
      subject: "Newer update",
      event_type: "rescheduled",
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )

    expect(described_class.recent_first.first(2)).to eq([newer_log, older_log])
  end
end
