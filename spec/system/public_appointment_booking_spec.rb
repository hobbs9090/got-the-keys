require "rails_helper"

RSpec.describe "Public appointment booking", type: :system, js: true do
  include ActiveSupport::Testing::TimeHelpers

  def dismiss_cookie_banner
    return unless page.has_button?("Reject non-essential", wait: 1)

    click_button "Reject non-essential"
    expect(page).to have_no_css(".cookie-banner", wait: 5)
  end

  def sign_in_as_user(user, password: "changeme")
    visit new_user_session_path

    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button "Sign in"
  end

  around do |example|
    travel_to(Time.zone.local(2026, 4, 6, 8, 0)) { example.run }
  end

  before do
    configure_booking_rules!(open_weekdays: %w[1 2 3 4 5], office_opens_at: "09:00", office_closes_at: "17:00")
  end

  it "prompts visitors to sign in before they can book a viewing" do
    user = FactoryBot.create(:user)
    property = FactoryBot.create(:property, user:, address_line_1: "88 Harbour View")

    visit for_sale_index_path

    expect(page).to have_text("88 Harbour View")
    expect(page).to have_link("Sign in to book a viewing", href: new_user_session_path(return_to: property_path(property, anchor: "booking-panel")))

    click_link "88 Harbour View"

    expect(page).to have_current_path(property_path(property))
    dismiss_cookie_banner
    expect(page).to have_text("Book a viewing")
    expect(page).to have_link("Sign in to book a viewing", href: new_user_session_path(return_to: property_path(property, anchor: "booking-panel")))
    expect(page).to have_no_css('[data-testid="appointment-form"]')
  end

  it "lets a signed-in user prepare a viewing request" do
    user = FactoryBot.create(
      :user,
      first_name: "Nina",
      last_name: "Hughes",
      email: "nina.hughes@example.com",
      mobile_number: "07700 930005"
    )
    property = FactoryBot.create(:property, user:, address_line_1: "88 Harbour View")

    sign_in_as_user(user)
    visit property_path(property)

    dismiss_cookie_banner
    expect(page).to have_css('[data-testid="appointment-form"]')

    within('[data-testid="appointment-form"]') do
      slot_button = find("[data-testid='requested-time-picker'] .appointment-slot-picker__time-group.is-active [data-slot-picker-time]", match: :first)
      selected_slot = slot_button["data-slot-picker-time"]

      slot_button.click

      expect(find("#appointment_requested_time", visible: false).value).to eq(selected_slot)
      fill_in "appointment_notes", with: "Please confirm whether parking is allocated."
    end

    expect(page).to have_field("appointment_customer_name", with: "Nina Hughes")
    expect(page).to have_field("appointment_customer_email", with: "nina.hughes@example.com", readonly: true)
    expect(page).to have_field("appointment_customer_phone", with: "07700 930005")
  end
end
