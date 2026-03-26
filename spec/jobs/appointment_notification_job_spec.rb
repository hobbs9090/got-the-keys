require "rails_helper"

RSpec.describe AppointmentNotificationJob do
  let(:user) { FactoryBot.create(:user) }
  let(:property) { FactoryBot.create(:property, user:, address_line_1: "44 Mount Ephraim") }
  let(:appointment) do
    slot = next_booking_slot(hour: 13)

    FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Owen Clark",
      customer_email: "owen.clark@example.com",
      customer_phone: "07700 930006",
      requested_time: slot,
      scheduled_at: slot,
      duration_minutes: 45
    )
  end

  it "delegates delivery to AppointmentNotifier" do
    notifier = instance_double(AppointmentNotifier, deliver: true)

    allow(AppointmentNotifier).to receive(:new).with(appointment, event_type: "confirmed").and_return(notifier)

    described_class.perform_now(appointment.id, "confirmed")

    expect(AppointmentNotifier).to have_received(:new).with(appointment, event_type: "confirmed")
    expect(notifier).to have_received(:deliver)
  end

  it "discards missing appointments cleanly" do
    expect do
      described_class.perform_now(-1, "confirmed")
    end.not_to raise_error
  end
end
