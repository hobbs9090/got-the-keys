require "rails_helper"
require "nokogiri"

RSpec.describe "Admin booking configuration" do
  let(:admin) { FactoryBot.create(:admin, email: "booking-rules-admin@gotthekeys.com", password: "changeme123", password_confirmation: "changeme123") }

  before do
    sign_in admin
  end

  it "renders the booking configuration form with testid anchors" do
    get admin_booking_configuration_path

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    form = document.at_css('[data-testid="booking-configuration-form"]')

    expect(form).to be_present
    expect(form.at_css('[data-testid="booking-config-slot-duration"]')).to be_present
    expect(form.at_css('[data-testid="booking-config-window-days"]')).to be_present
    expect(form.at_css('[data-testid="booking-config-lead-time"]')).to be_present
    expect(form.at_css('[data-testid="booking-config-buffer"]')).to be_present
    expect(form.at_css('[data-testid="booking-config-submit"]')).to be_present
  end

  it "updates the booking configuration" do
    patch admin_booking_configuration_path, params: {
      booking_configuration: {
        slot_duration_minutes: 60,
        booking_window_days: 21,
        lead_time_hours: 24,
        buffer_minutes: 15,
        office_opens_at: "09:00",
        office_closes_at: "17:00",
        open_weekdays: ["1", "2", "3", "4", "5"]
      }
    }

    expect(response).to redirect_to(admin_booking_configuration_path)
    config = BookingConfiguration.current
    expect(config.slot_duration_minutes).to eq(60)
    expect(config.booking_window_days).to eq(21)
    expect(config.lead_time_hours).to eq(24)
    expect(config.buffer_minutes).to eq(15)
  end
end
