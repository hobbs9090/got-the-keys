require "rails_helper"

RSpec.describe Appointment do
  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin, email: "steven@gotthekeys.com") }
  let(:property) { user.properties.create!(property_attributes(address_line_1: "18 Cedar Road")) }

  def next_open_slot(hour: 10, minutes: 0)
    configuration = BookingConfiguration.current
    date = Date.current

    loop do
      candidate = Time.zone.local(date.year, date.month, date.day, hour, minutes)
      return candidate if configuration.open_on?(date) && candidate > Time.current + configuration.lead_time_hours.hours

      date += 1.day
    end
  end

  before do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "generates public access fields and records a creation event" do
    appointment = nil

    expect do
      appointment = property.appointments.create!(
        customer_name: "Ruby Owen",
        customer_email: "ruby.owen@example.com",
        customer_phone: "07700 930001",
        requested_time: next_open_slot,
        notes: "Please confirm parking arrangements."
      )
    end.to have_enqueued_job(AppointmentNotificationJob).with(kind_of(Integer), "created")

    expect(appointment.public_reference).to start_with("GTK-")
    expect(appointment.access_token).to be_present
    expect(appointment.appointment_events.count).to eq(1)
    expect(appointment.appointment_events.first.event_type).to eq("created")
  end

  it "prevents overlapping active appointments on the same property" do
    slot = next_open_slot(hour: 11)

    property.appointments.create!(
      admin: admin,
      customer_name: "Alice Morgan",
      customer_email: "alice.morgan@example.com",
      customer_phone: "07700 930002",
      requested_time: slot,
      scheduled_at: slot,
      duration_minutes: 45,
      status: "confirmed"
    )

    overlapping = property.appointments.new(
      admin: admin,
      customer_name: "Ben Storey",
      customer_email: "ben.storey@example.com",
      customer_phone: "07700 930003",
      requested_time: slot,
      scheduled_at: slot,
      duration_minutes: 45,
      status: "confirmed"
    )

    expect(overlapping).not_to be_valid
    expect(overlapping.errors[:scheduled_at]).to include("is not available because it conflicts with another appointment or falls outside the booking rules")
  end

  it "creates a status event when the appointment is updated" do
    appointment = property.appointments.create!(
      customer_name: "Chloe White",
      customer_email: "chloe.white@example.com",
      customer_phone: "07700 930004",
      requested_time: next_open_slot(hour: 12),
      scheduled_at: next_open_slot(hour: 12),
      duration_minutes: 45,
      status: "pending"
    )

    expect do
      appointment.update!(status: "confirmed", admin: admin)
    end.to have_enqueued_job(AppointmentNotificationJob).with(appointment.id, "confirmed")

    expect(appointment.appointment_events.count).to eq(2)
    expect(appointment.appointment_events.order(:created_at).last.event_type).to eq("confirmed")
  end

  it "requires a customer phone number" do
    appointment = property.appointments.new(
      customer_name: "Mia Hart",
      customer_email: "mia.hart@example.com",
      customer_phone: "",
      requested_time: next_open_slot(hour: 13)
    )

    expect(appointment).not_to be_valid
    expect(appointment.errors[:customer_phone]).to include("can't be blank")
  end

  it "rejects an invalid customer phone number" do
    appointment = property.appointments.new(
      customer_name: "Mia Hart",
      customer_email: "mia.hart@example.com",
      customer_phone: "invalid-number",
      requested_time: next_open_slot(hour: 13)
    )

    expect(appointment).not_to be_valid
    expect(appointment.errors[:customer_phone]).to include("must be a valid phone number")
  end
end
