require "rails_helper"
require "nokogiri"

RSpec.describe "Admin customers", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "customers-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  it "shows grouped customers from bookings with a CTA to filtered appointments" do
    property = FactoryBot.create(:property)
    FactoryBot.create(
      :appointment,
      :pending,
      property: property,
      customer_name: "Alex Buyer",
      customer_email: "alex.buyer@example.com",
      customer_phone: "07700 930010"
    )
    FactoryBot.create(
      :appointment,
      :confirmed,
      property: property,
      customer_name: "Alex Buyer",
      customer_email: "alex.buyer@example.com",
      customer_phone: "07700 930010"
    )

    get admin_customers_path

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    row = document.at_css('[data-testid="admin-customer-row-alex-buyer-example-com"]')
    bookings_link = document.at_css('[data-testid="admin-customer-view-bookings-alex-buyer-example-com"]')

    expect(row).to be_present
    expect(row.text).to include("Alex Buyer", "alex.buyer@example.com", "2 bookings")
    expect(bookings_link).to be_present
    expect(bookings_link["href"]).to eq(admin_appointments_path(view: "agenda", customer_email: "alex.buyer@example.com"))
  end
end
