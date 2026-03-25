require "rails_helper"

RSpec.describe AppointmentNotifier do
  include ActiveSupport::Testing::TimeHelpers

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

  before do
    BookingConfiguration.current.update!(
      slot_duration_minutes: 45,
      lead_time_hours: 4,
      buffer_minutes: 15,
      office_opens_at: "09:00",
      office_closes_at: "17:00",
      open_weekdays: %w[1 2 3 4 5]
    )
  end

  around do |example|
    travel_to(Time.zone.local(2026, 3, 30, 8, 0)) { example.run }
  end

  before do
    appointment
    NotificationLog.delete_all
    ActionMailer::Base.deliveries.clear
  end

  it "delivers the mail and records a sent notification in test" do
    expect do
      described_class.new(appointment, event_type: "confirmed").deliver
    end.to change(NotificationLog, :count).by(1)

    log = NotificationLog.last

    expect(log.status).to eq("sent")
    expect(log.recipient_email).to eq("owen.clark@example.com")
    expect(log.subject).to eq("GotTheKeys viewing confirmed: #{appointment.public_reference}")
    expect(log.body_preview).to include("Hello Owen Clark")
    expect(log.metadata).to include(
      "appointment_reference" => appointment.public_reference,
      "property_id" => property.id
    )
    expect(ActionMailer::Base.deliveries.last.subject).to eq(log.subject)
  end

  it "records a skipped notification when production SMTP is unavailable" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

    expect do
      described_class.new(appointment, event_type: "confirmed").deliver
    end.to change(NotificationLog, :count).by(1)

    log = NotificationLog.last

    expect(log.status).to eq("skipped")
    expect(log.error_message).to eq("SMTP is not configured for this environment.")
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "records a failed notification when delivery raises an error" do
    preview = double("preview", encoded: "<p>Delivery preview</p>")
    failing_mail = double("mail", body: preview, subject: "Broken subject")
    mailer = double("mailer", status_update: failing_mail)

    allow(failing_mail).to receive(:deliver_now).and_raise(RuntimeError, "SMTP timeout")
    allow(AppointmentMailer).to receive(:with).with(appointment: appointment, event_type: "confirmed").and_return(mailer)

    expect do
      described_class.new(appointment, event_type: "confirmed").deliver
    end.to change(NotificationLog, :count).by(1)

    log = NotificationLog.last

    expect(log.status).to eq("failed")
    expect(log.subject).to eq("Broken subject")
    expect(log.error_message).to eq("RuntimeError: SMTP timeout")
  end
end
