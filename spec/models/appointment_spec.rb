require "rails_helper"

RSpec.describe Appointment do
  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin, email: "steven@gotthekeys.com") }
  let(:property) { FactoryBot.create(:property, user:, address_line_1: "18 Cedar Road") }

  before do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "generates public access fields and records a creation event" do
    appointment = nil

    expect do
      appointment = FactoryBot.create(
        :appointment,
        property:,
        customer_name: "Ruby Owen",
        customer_email: "ruby.owen@example.com",
        customer_phone: "07700 930001",
        requested_time: next_booking_slot,
        notes: "Please confirm parking arrangements."
      )
    end.to have_enqueued_job(AppointmentNotificationJob).with(kind_of(Integer), "created")

    expect(appointment.public_reference).to start_with("GTK-")
    expect(appointment.access_token).to be_present
    expect(appointment.appointment_events.count).to eq(1)
    expect(appointment.appointment_events.first.event_type).to eq("created")
  end

  it "prevents overlapping active appointments on the same property" do
    slot = next_booking_slot(hour: 11)

    FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      admin: admin,
      customer_name: "Alice Morgan",
      customer_email: "alice.morgan@example.com",
      customer_phone: "07700 930002",
      requested_time: slot,
      scheduled_at: slot,
      duration_minutes: 45
    )

    overlapping = FactoryBot.build(
      :appointment,
      :confirmed,
      property:,
      admin: admin,
      customer_name: "Ben Storey",
      customer_email: "ben.storey@example.com",
      customer_phone: "07700 930003",
      requested_time: slot,
      scheduled_at: slot,
      duration_minutes: 45
    )

    expect(overlapping).not_to be_valid
    expect(overlapping.errors[:scheduled_at]).to include("is not available because it conflicts with another appointment or falls outside the booking rules")
  end

  it "creates a status event when the appointment is updated" do
    slot = next_booking_slot(hour: 12)
    appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Chloe White",
      customer_email: "chloe.white@example.com",
      customer_phone: "07700 930004",
      requested_time: slot,
      scheduled_at: slot,
      duration_minutes: 45
    )

    expect do
      appointment.update!(status: "confirmed", admin: admin)
    end.to have_enqueued_job(AppointmentNotificationJob).with(appointment.id, "confirmed")

    expect(appointment.appointment_events.count).to eq(2)
    expect(appointment.appointment_events.order(:created_at).last.event_type).to eq("confirmed")
  end

  it "requires a customer phone number" do
    appointment = FactoryBot.build(
      :appointment,
      property:,
      customer_name: "Mia Hart",
      customer_email: "mia.hart@example.com",
      customer_phone: "",
      requested_time: next_booking_slot(hour: 13)
    )

    expect(appointment).not_to be_valid
    expect(appointment.errors[:customer_phone]).to include("can't be blank")
  end

  it "rejects an invalid customer phone number" do
    appointment = FactoryBot.build(
      :appointment,
      property:,
      customer_name: "Mia Hart",
      customer_email: "mia.hart@example.com",
      customer_phone: "invalid-number",
      requested_time: next_booking_slot(hour: 13)
    )

    expect(appointment).not_to be_valid
    expect(appointment.errors[:customer_phone]).to include("must be a valid phone number")
  end

  it "supports customer self-service before the appointment expires" do
    appointment = FactoryBot.create(
      :appointment,
      property:,
      requested_time: next_booking_slot(hour: 15),
      scheduled_at: next_booking_slot(hour: 15)
    )

    expect(appointment.manageable_by_customer?).to be(true)
    expect(appointment.valid_access_token?(appointment.access_token)).to be(true)
  end

  it "records a visit outcome event when follow-up progress is updated" do
    appointment = FactoryBot.create(
      :appointment,
      :completed,
      property:,
      admin: admin,
      requested_time: next_booking_slot(hour: 10, from: Time.zone.local(2026, 3, 29, 8, 0)),
      scheduled_at: next_booking_slot(hour: 10, from: Time.zone.local(2026, 3, 29, 8, 0))
    )

    appointment.update!(visit_outcome: "feedback_requested", admin: admin)

    expect(appointment.timeline.last.event_type).to eq("feedback_requested")
    expect(appointment.timeline.last.message).to include(I18n.t("ui.appointments.visit_outcomes.feedback_requested"))
  end

  it "rejects completed and no-show statuses for future appointments" do
    future_slot = next_booking_slot(hour: 14)
    appointment = FactoryBot.build(
      :appointment,
      property:,
      requested_time: future_slot,
      scheduled_at: future_slot,
      status: "completed"
    )

    expect(appointment).not_to be_valid
    expect(appointment.errors[:status]).to include("can only be marked once the appointment time has passed")

    appointment.status = "no_show"

    expect(appointment).not_to be_valid
    expect(appointment.errors[:status]).to include("can only be marked once the appointment time has passed")
  end
end
