require "rails_helper"

RSpec.describe NotificationLog do
  let(:user) { FactoryBot.create(:user) }
  let(:property) { user.properties.create!(property_attributes(user_id: user.id)) }
  let(:appointment) do
    property.appointments.create!(
      customer_name: "Asha Patel",
      customer_email: "asha@example.com",
      customer_phone: "07700 900222",
      requested_time: Time.zone.local(2026, 4, 4, 12, 0),
      scheduled_at: Time.zone.local(2026, 4, 4, 12, 0),
      duration_minutes: 45,
      status: "pending"
    )
  end

  before do
    appointment
    described_class.delete_all
  end

  it "validates the allowed statuses" do
    log = described_class.new(subject: "Status update", event_type: "confirmed", status: "queued")

    expect(log).not_to be_valid
    expect(log.errors[:status]).to include("is not included in the list")
  end

  it "allows logs without an appointment association" do
    log = described_class.new(subject: "General notice", event_type: "export", status: "sent")

    expect(log).to be_valid
  end

  it "orders logs with the newest entry first" do
    older_log = described_class.create!(
      appointment: appointment,
      subject: "Older update",
      event_type: "confirmed",
      status: "sent",
      created_at: 2.days.ago,
      updated_at: 2.days.ago
    )
    newer_log = described_class.create!(
      appointment: appointment,
      subject: "Newer update",
      event_type: "rescheduled",
      status: "failed",
      created_at: 1.day.ago,
      updated_at: 1.day.ago
    )

    expect(described_class.recent_first.first(2)).to eq([newer_log, older_log])
  end
end
