require "rails_helper"
require "nokogiri"

RSpec.describe "Admin notification logs" do
  let(:admin) { FactoryBot.create(:admin, email: "notif-logs-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }
  let(:property) { FactoryBot.create(:property) }

  before do
    sign_in admin
  end

  it "renders notification log rows with stable testid anchors" do
    appointment = FactoryBot.create(:appointment, property:)
    FactoryBot.create(:notification_log, appointment:, subject: "Booking confirmed", recipient_email: "viewer@example.com", status: "sent")

    get admin_notification_logs_path

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    rows = document.css('[data-testid="notification-log-row"]')

    expect(rows.length).to eq(1)
    expect(rows.first.text).to include("Booking confirmed")
    expect(rows.first.text).to include("viewer@example.com")
  end

  it "renders an empty list when there are no notification logs" do
    get admin_notification_logs_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(%(data-testid="notification-log-row"))
  end
end
