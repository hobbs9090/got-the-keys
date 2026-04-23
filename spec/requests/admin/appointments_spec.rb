require "rails_helper"
require "nokogiri"

RSpec.describe "Admin appointments" do
  let(:admin) { FactoryBot.create(:admin, email: "steven@gotthekeys.uk", password: "changeme", password_confirmation: "changeme") }
  let(:user) { FactoryBot.create(:user) }
  let(:property) { FactoryBot.create(:property, user:, address_line_1: "9 Park Lane") }

  before do
    sign_in admin
  end

  it "shows the admin-only bookings desk" do
    FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Row Check",
      customer_email: "row.check@example.com",
      requested_time: next_booking_slot(hour: 10),
      scheduled_at: next_booking_slot(hour: 10),
      status: "rescheduled"
    )

    get admin_bookings_path
    document = Nokogiri::HTML.parse(response.body)
    view_switch = document.at_css('[data-testid="admin-bookings-view-switch"]')
    agenda_days = document.at_css('[data-testid="admin-bookings-agenda-days"]')
    agenda_list = document.at_css('[data-testid="admin-bookings-agenda-list"]')
    first_actions = document.at_css('[data-testid="admin-bookings-row-actions"]')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Bookings desk")
    expect(view_switch).to be_present
    expect(view_switch["class"]).to include("admin-bookings-view-switch")
    expect(view_switch.css("a").map { |link| link.text.strip }).to eq(%w[Agenda Day Week Month])
    expect(view_switch.at_css('[data-testid="admin-bookings-view-agenda"]')["class"]).to include("is-active")
    expect(agenda_days).to be_present
    expect(agenda_days["class"]).to include("admin-bookings-agenda-days")
    expect(agenda_list).to be_present
    expect(agenda_list["class"]).to include("admin-bookings-agenda-list")
    expect(first_actions).to be_present
    expect(first_actions["class"]).to include("admin-bookings-row__actions")
    expect(first_actions.at_css(".admin-bookings-row__pill")).to be_present
  end

  it "redirects non-admin visitors away from the bookings desk" do
    sign_out admin

    get admin_bookings_path

    expect(response).to redirect_to(new_admin_session_path)
  end

  it "allows an admin to confirm a pending appointment" do
    slot = next_booking_slot
    appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Priya Shah",
      customer_email: "priya.shah@example.com",
      customer_phone: "07700 930007",
      requested_time: slot,
      scheduled_at: slot,
      status: "pending"
    )

    patch transition_admin_appointment_path(appointment, status: "confirmed")

    expect(response).to redirect_to(admin_appointments_path)
    expect(appointment.reload.status).to eq("confirmed")
    expect(appointment.admin).to eq(admin)
  end

  it "does not allow an admin to mark a future appointment as no show" do
    slot = next_booking_slot(hour: 15)
    appointment = FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      customer_name: "Priya Shah",
      customer_email: "priya.shah@example.com",
      customer_phone: "07700 930007",
      requested_time: slot,
      scheduled_at: slot
    )

    patch transition_admin_appointment_path(appointment, status: "no_show")

    expect(response).to redirect_to(admin_appointments_path)
    expect(flash[:alert]).to eq("Status can only be marked once the appointment time has passed")
    expect(appointment.reload.status).to eq("confirmed")
  end

  it "does not allow an admin to confirm a completed appointment" do
    slot = booking_time(2026, 3, 31, 11, 0)
    appointment = FactoryBot.create(
      :appointment,
      :completed,
      property:,
      customer_name: "Priya Shah",
      customer_email: "priya.shah@example.com",
      customer_phone: "07700 930007",
      requested_time: slot,
      scheduled_at: slot
    )

    patch transition_admin_appointment_path(appointment, status: "confirmed")

    expect(response).to redirect_to(admin_appointments_path)
    expect(flash[:alert]).to eq("Status cannot be changed back to confirmed once completed")
    expect(appointment.reload.status).to eq("completed")
  end

  it "renders the appointment detail page in the admin's locale" do
    admin.update!(language: "de")
    slot = next_booking_slot(hour: 11)
    appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Maya Singh",
      customer_email: "maya.singh@example.com",
      customer_phone: "07700 930008",
      requested_time: slot,
      scheduled_at: slot,
      status: "pending"
    )

    get admin_appointment_path(appointment)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Termindetails")
    expect(response.body).to include("Zusammenfassung")
    expect(response.body).to include("Kundenhistorie")
    expect(response.body).to include(%(data-testid="admin-appointment-header-actions"))
  end

  it "filters the bookings desk by status and customer email" do
    matching_slot = next_booking_slot(hour: 12)
    matching = FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      customer_name: "Filtered Match",
      customer_email: "filtered.match@example.com",
      requested_time: matching_slot,
      scheduled_at: matching_slot
    )
    other_slot = next_booking_slot(hour: 14)
    FactoryBot.create(
      :appointment,
      :pending,
      property:,
      customer_name: "Other Viewer",
      customer_email: "other.viewer@example.com",
      requested_time: other_slot,
      scheduled_at: other_slot
    )

    get admin_bookings_path, params: { status: "confirmed", customer_email: "FILTERED.MATCH@example.com" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(matching.customer_name)
    expect(response.body).not_to include("Other Viewer")
  end

  it "filters the bookings desk by the registered user's current email when the stored booking email is stale" do
    user = FactoryBot.create(
      :user,
      first_name: "Zoe",
      last_name: "Bates",
      email: "zoe.bates@example.com",
      mobile_number: "07700 930099"
    )
    matching_slot = next_booking_slot(hour: 12)
    matching = FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      customer_name: user.full_name,
      customer_email: "zoe.bates@exmaple.com",
      customer_phone: user.mobile_number,
      requested_time: matching_slot,
      scheduled_at: matching_slot
    )
    FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      customer_name: "Other Viewer",
      customer_email: "other.viewer@example.com",
      customer_phone: "07700 930010",
      requested_time: next_booking_slot(hour: 14),
      scheduled_at: next_booking_slot(hour: 14)
    )

    get admin_bookings_path, params: { customer_email: user.email }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(matching.customer_name)
    expect(response.body).not_to include("Other Viewer")
  end

  it "includes a property link on agenda rows for customer-filtered bookings" do
    slot = next_booking_slot(hour: 12)
    appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: "Zoe Bates",
      customer_email: "zoe.bates@exmaple.com",
      requested_time: slot,
      scheduled_at: slot,
      status: "confirmed"
    )

    get admin_bookings_path, params: { customer_email: appointment.customer_email, view: "agenda" }

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    property_link = document.at_css(%([data-testid="admin-appointment-property-link-#{appointment.id}"]))
    reference = document.at_css(%([data-testid="admin-appointment-reference-#{appointment.id}"]))

    expect(property_link).to be_present
    expect(property_link.text.strip).to eq("9 Park Lane")
    expect(property_link["href"]).to eq(admin_property_path(property))
    expect(reference).to be_present
    expect(reference.text.strip).to eq(appointment.public_reference)
  end

  it "links the booking customer to the customer profile and includes a details link for the appointment" do
    user = FactoryBot.create(
      :user,
      first_name: "Zoe",
      last_name: "Bates",
      email: "zoe.bates@example.com",
      mobile_number: "07700 930099"
    )
    slot = next_booking_slot(hour: 12)
    appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: user.full_name,
      customer_email: "zoe.bates@exmaple.com",
      customer_phone: user.mobile_number,
      requested_time: slot,
      scheduled_at: slot,
      status: "confirmed"
    )

    get admin_bookings_path, params: { customer_email: user.email, view: "agenda" }

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    customer_link = document.at_css(%([data-testid="admin-appointment-customer-link-#{appointment.id}"]))
    details_link = document.at_css(%([data-testid="admin-appointment-details-link-#{appointment.id}"]))

    expect(customer_link).to be_present
    expect(customer_link["href"]).to eq(admin_customer_path(user.email))
    expect(customer_link.text.strip).to eq("Zoe Bates")

    expect(details_link).to be_present
    expect(details_link["href"]).to eq(admin_appointment_path(appointment))
    expect(details_link.text.strip).to eq("Details")
  end

  it "does not show a confirm action for completed bookings on the desk or detail page" do
    slot = booking_time(2026, 3, 31, 11, 0)
    appointment = FactoryBot.create(
      :appointment,
      :completed,
      property:,
      customer_name: "Priya Shah",
      customer_email: "priya.shah@example.com",
      customer_phone: "07700 930007",
      requested_time: slot,
      scheduled_at: slot
    )

    get admin_bookings_path, params: { view: "agenda" }
    expect(response.body).not_to include(transition_admin_appointment_path(appointment, status: "confirmed"))

    get admin_appointment_path(appointment)
    expect(response.body).not_to include(transition_admin_appointment_path(appointment, status: "confirmed"))
  end

  it "does not show a confirm action for past bookings or no-show bookings" do
    past_appointment = FactoryBot.create(
      :appointment,
      :pending,
      property:,
      customer_name: "Past Pending",
      customer_email: "past.pending@example.com",
      customer_phone: "07700 930101",
      requested_time: booking_time(2026, 3, 31, 11, 0),
      scheduled_at: booking_time(2026, 3, 31, 11, 0),
      duration_minutes: 60,
      skip_slot_validation: true
    )
    no_show_appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: "No Show Viewer",
      customer_email: "no.show@example.com",
      customer_phone: "07700 930102",
      requested_time: booking_time(2026, 3, 31, 13, 0),
      scheduled_at: booking_time(2026, 3, 31, 13, 0),
      duration_minutes: 60,
      status: "no_show",
      skip_slot_validation: true
    )

    get admin_bookings_path, params: { view: "agenda" }

    expect(response.body).not_to include(%(data-testid="admin-appointment-confirm-#{past_appointment.id}"))
    expect(response.body).not_to include(%(data-testid="admin-appointment-confirm-#{no_show_appointment.id}"))

    get admin_appointment_path(past_appointment)
    expect(response.body).not_to include(transition_admin_appointment_path(past_appointment, status: "confirmed"))

    get admin_appointment_path(no_show_appointment)
    expect(response.body).not_to include(transition_admin_appointment_path(no_show_appointment, status: "confirmed"))
  end

  it "shows the registered user's current email on the admin appointment detail page" do
    user = FactoryBot.create(
      :user,
      first_name: "Zoe",
      last_name: "Bates",
      email: "zoe.bates@example.com",
      mobile_number: "07700 930099"
    )
    slot = next_booking_slot(hour: 11)
    appointment = FactoryBot.create(
      :appointment,
      property:,
      customer_name: user.full_name,
      customer_email: "zoe.bates@exmaple.com",
      customer_phone: user.mobile_number,
      requested_time: slot,
      scheduled_at: slot,
      status: "confirmed"
    )

    get admin_appointment_path(appointment)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("zoe.bates@example.com")
    expect(response.body).not_to include("zoe.bates@exmaple.com")
  end

  it "filters the bookings desk by date range and visit outcome" do
    matching = FactoryBot.create(
      :appointment,
      :completed,
      property:,
      customer_name: "Feedback Lead",
      requested_time: booking_time(2026, 3, 31, 11, 0),
      scheduled_at: booking_time(2026, 3, 31, 11, 0),
      visit_outcome: "feedback_requested"
    )
    FactoryBot.create(
      :appointment,
      :completed,
      property:,
      customer_name: "Outside Range",
      requested_time: booking_time(2026, 3, 25, 11, 0),
      scheduled_at: booking_time(2026, 3, 25, 11, 0),
      visit_outcome: "attended"
    )

    get admin_bookings_path, params: { from: "2026-03-30", to: "2026-04-01", visit_outcome: "feedback_requested" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Feedback Lead")
    expect(response.body).not_to include("Outside Range")
    expect(response.body).to include(%(data-testid="admin-bookings-filters"))

    document = Nokogiri::HTML.parse(response.body)
    expect(document.at_css('[data-testid="admin-bookings-filter-apply"]')).to be_present
    expect(document.at_css('[data-testid="admin-bookings-filter-reset"]')).to be_present
    expect(document.at_css('[data-testid="bookings-filter-queue"]')).to be_present
  end

  it "filters the bookings desk by the pending action queue" do
    pending_slot = next_booking_slot(hour: 11)
    pending = FactoryBot.create(:appointment, :pending, property:, customer_name: "Queued Pending", requested_time: pending_slot, scheduled_at: pending_slot)
    rescheduled_slot = next_booking_slot(hour: 13)
    rescheduled = FactoryBot.create(:appointment, property:, customer_name: "Queued Rescheduled", requested_time: rescheduled_slot, scheduled_at: rescheduled_slot, status: "rescheduled")
    confirmed_slot = next_booking_slot(hour: 15)
    FactoryBot.create(:appointment, :confirmed, property:, customer_name: "Not In Queue", requested_time: confirmed_slot, scheduled_at: confirmed_slot)

    get admin_bookings_path, params: { queue: "pending_action" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(pending.customer_name)
    expect(response.body).to include(rescheduled.customer_name)
    expect(response.body).not_to include("Not In Queue")
  end

  it "shows confirm and cancel testid anchors on pending appointment rows" do
    slot = next_booking_slot(hour: 10)
    appointment = FactoryBot.create(:appointment, :pending, property:, customer_name: "Action Row", requested_time: slot, scheduled_at: slot)

    get admin_bookings_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-testid="admin-appointment-confirm-#{appointment.id}"))
    expect(response.body).to include(%(data-testid="admin-appointment-cancel-#{appointment.id}"))
  end

  it "queues a reminder from the admin detail page" do
    appointment = FactoryBot.create(:appointment, property:, requested_time: next_booking_slot(hour: 11), scheduled_at: next_booking_slot(hour: 11))

    expect do
      post send_reminder_admin_appointment_path(appointment)
    end.to have_enqueued_job(AppointmentNotificationJob).with(appointment.id, "reminder")

    expect(response).to redirect_to(admin_appointment_path(appointment))
    expect(appointment.reload.reminder_sent_at).to be_present
  end
end
