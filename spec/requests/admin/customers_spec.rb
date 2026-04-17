require "rails_helper"
require "nokogiri"

RSpec.describe "Admin customers", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "customers-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  it "shows a customer search form on the index" do
    property = FactoryBot.create(:property)
    FactoryBot.create(
      :appointment,
      :pending,
      property:,
      customer_name: "Alex Buyer",
      customer_email: "alex.buyer@example.com",
      customer_phone: "07700 930010"
    )
    FactoryBot.create(
      :appointment,
      :pending,
      property:,
      customer_name: "Taylor Stone",
      customer_email: "taylor.stone@example.com",
      customer_phone: "07700 930011"
    )

    get admin_customers_path

    expect(response).to have_http_status(:ok)

    search_form = parsed_html.at_css('[data-testid="admin-customers-search"]')
    expect(search_form).to be_present
    expect(search_form["action"]).to eq(admin_customers_path)

    search_input = search_form.at_css('[data-testid="admin-customers-search-input"]')
    expect(search_input).to be_present
    expect(search_input["placeholder"]).to eq("Name, email, or phone")

    clear_link = search_form.at_css('[data-testid="admin-customers-search-clear"]')
    expect(clear_link).to be_present
    expect(clear_link["href"]).to eq(admin_customers_path)

    count_label = parsed_html.at_css('[data-testid="admin-customers-count"]')
    expect(count_label).to be_present
    expect(count_label.text.strip).to eq("2 customers total")
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

    document = parsed_html
    row = document.at_css('[data-testid="admin-customer-row-alex-buyer-example-com"]')
    bookings_link = document.at_css('[data-testid="admin-customer-view-bookings-alex-buyer-example-com"]')

    expect(row).to be_present
    expect(row.text).to include("Alex Buyer", "alex.buyer@example.com", "2 bookings")
    expect(bookings_link).to be_present
    expect(bookings_link["href"]).to eq(admin_appointments_path(view: "agenda", customer_email: "alex.buyer@example.com"))
  end

  it "filters customers by name and email, preserving the query value" do
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
      :pending,
      property: property,
      customer_name: "Taylor Stone",
      customer_email: "taylor.stone@example.com",
      customer_phone: "07700 930011"
    )

    get admin_customers_path, params: { q: "alex.buyer@" }

    expect(response).to have_http_status(:ok)

    row_ids = parsed_html.css('[data-testid^="admin-customer-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to eq(["admin-customer-row-alex-buyer-example-com"])

    search_input = parsed_html.at_css('[data-testid="admin-customers-search-input"]')
    expect(search_input["value"]).to eq("alex.buyer@")
  end

  it "treats q as case-insensitive" do
    property = FactoryBot.create(:property)
    FactoryBot.create(
      :appointment,
      :pending,
      property:,
      customer_name: "Alex Buyer",
      customer_email: "alex.buyer@example.com",
      customer_phone: "07700 930010"
    )
    FactoryBot.create(
      :appointment,
      :pending,
      property:,
      customer_name: "Taylor Stone",
      customer_email: "taylor.stone@example.com",
      customer_phone: "07700 930011"
    )

    get admin_customers_path, params: { q: "ALEx.BuYeR@" }

    expect(response).to have_http_status(:ok)
    row_ids = parsed_html.css('[data-testid^="admin-customer-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to eq(["admin-customer-row-alex-buyer-example-com"])
  end

  it "filters customers by phone and shows an empty state when there are no matches" do
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
      :pending,
      property: property,
      customer_name: "Taylor Stone",
      customer_email: "taylor.stone@example.com",
      customer_phone: "07700 930011"
    )

    get admin_customers_path, params: { q: "930011" }

    expect(response).to have_http_status(:ok)

    row_ids = parsed_html.css('[data-testid^="admin-customer-row-"]').map { |row| row["data-testid"] }
    expect(row_ids).to eq(["admin-customer-row-taylor-stone-example-com"])

    get admin_customers_path, params: { q: "nobody here" }

    expect(response).to have_http_status(:ok)

    empty_copy = parsed_html.at_css(".empty-copy")
    expect(empty_copy).to be_present
    expect(empty_copy.text.strip).to eq("No customers with bookings yet.")
  end
end
