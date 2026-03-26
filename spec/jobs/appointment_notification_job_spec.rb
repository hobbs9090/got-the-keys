require "rails_helper"

RSpec.describe AppointmentNotificationJob do
  let(:user) { FactoryBot.create(:user) }
  let(:property) do
    user.properties.create!(
      property_attributes(
        user_id: user.id,
        address_line_1: "44 Mount Ephraim",
        bathrooms: 2,
        property_type: "House",
        property_description: "A spacious family home with a practical layout, modern finishes, and a private garden."
      )
    )
  end
  let(:appointment) do
    property.appointments.create!(
      customer_name: "Owen Clark",
      customer_email: "owen.clark@example.com",
      customer_phone: "07700 930006",
      requested_time: Time.zone.local(2026, 3, 30, 13, 0),
      scheduled_at: Time.zone.local(2026, 3, 30, 13, 0),
      duration_minutes: 45,
      status: "pending"
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
