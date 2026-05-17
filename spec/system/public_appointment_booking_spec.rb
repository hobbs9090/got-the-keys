require "rails_helper"

RSpec.describe "Public appointment booking", type: :system, js: true do
  include ActiveSupport::Testing::TimeHelpers
  include Warden::Test::Helpers

  def dismiss_cookie_banner
    return unless page.has_button?("Reject non-essential", wait: 1)

    click_button "Reject non-essential"
    expect(page).to have_no_css(".cookie-banner", wait: 5)
  end

  def sign_in_as_user(user, password: "changeme123")
    expect(user.valid_password?(password)).to be(true)
    login_as(user, scope: :user)
  end

  after { Warden.test_reset! }

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
    expect(page).to have_no_link("Sign in to book a viewing", href: new_user_session_path(return_to: property_path(property, anchor: "booking-panel")))

    click_link "88 Harbour View"

    expect(page).to have_current_path(property_path(property))
    dismiss_cookie_banner
    expect(page).to have_text("Book a viewing")
    expect(page).to have_link("Sign in to book a viewing", href: new_user_session_path(return_to: property_path(property, anchor: "booking-panel")))
    expect(page).to have_no_css('[data-testid="appointment-form"]')
  end

  it "activates the matching time slot group when a date is selected" do
    user = FactoryBot.create(:user)
    property = FactoryBot.create(:property, user:)

    sign_in_as_user(user)
    visit property_path(property)

    dismiss_cookie_banner

    date_buttons = all("[data-slot-picker-date]")
    next_date_button = date_buttons.find { |b| !b[:class].to_s.include?("is-selected") }
    next unless next_date_button

    next_date_key = next_date_button["data-slot-picker-date"]
    next_date_button.click

    expect(page).to have_css("[data-slot-picker-time-group='#{next_date_key}'].is-active")
    expect(page).to have_no_css("[data-slot-picker-time-group='#{next_date_key}'][hidden]")
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
    expect(page).to have_css('[data-testid="appointment-customer-email-display"]', text: "nina.hughes@example.com")
    expect(page).to have_field("appointment_customer_email", type: "hidden", with: "nina.hughes@example.com", visible: false)
    expect(page).to have_field("appointment_customer_phone", with: "07700 930005")
  end
end
