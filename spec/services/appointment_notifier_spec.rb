require "rails_helper"

RSpec.describe AppointmentNotifier do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:property) { FactoryBot.create(:property, user:, address_line_1: "44 Mount Ephraim") }
  let(:appointment) do
    FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Owen Clark",
      customer_email: "owen.clark@example.com",
      customer_phone: "07700 930006",
      requested_time: booking_time(2026, 3, 30, 13, 0),
      scheduled_at: booking_time(2026, 3, 30, 13, 0),
      duration_minutes: 45
    )
  end

  before do
    configure_booking_rules!
  end

  around do |example|
    travel_to(Time.zone.local(2026, 3, 30, 8, 0)) do
      I18n.with_locale(:en) { example.run }
    end
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

    delivered_mail = ActionMailer::Base.deliveries.last
    delivered_body = delivered_mail.body.encoded

    expect(delivered_mail.subject).to eq(log.subject)
    expect(delivered_mail.attachments.first.filename).to end_with(".ics")
    expect(delivered_body).to include("View or manage your appointment")
    expect(delivered_body).to include("token=#{appointment.access_token}")
  end

  it "supports reminder notifications" do
    described_class.new(appointment, event_type: "reminder").deliver

    expect(NotificationLog.last.subject).to eq("GotTheKeys viewing reminder: #{appointment.public_reference}")
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
