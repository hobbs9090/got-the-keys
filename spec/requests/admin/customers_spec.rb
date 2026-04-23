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
    expect(count_label.text.strip).to eq("3 customers total")
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
    customer_link = row.at_css('a[href="/admin/customers/alex.buyer@example.com"]')
    bookings_link = document.at_css('[data-testid="admin-customer-view-bookings-alex-buyer-example-com"]')

    expect(row).to be_present
    expect(row.text).to include("Alex Buyer", "alex.buyer@example.com", "2 bookings")
    expect(customer_link).to be_present
    expect(customer_link.text.strip).to eq("Alex Buyer")
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
    expect(empty_copy.text.strip).to eq("No customers match this search.")
  end

  it "includes registered users without bookings alongside booking customers" do
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
      :user,
      first_name: "Jamie",
      last_name: "Buyer",
      email: "jamie.buyer@example.com",
      mobile_number: "07700 930012"
    )
    seller = FactoryBot.create(
      :user,
      first_name: "Sage",
      last_name: "Seller",
      email: "sage.seller@example.com",
      mobile_number: "07700 930013"
    )
    FactoryBot.create(:property, user: seller)

    get admin_customers_path

    expect(response).to have_http_status(:ok)

    document = parsed_html
    row_ids = document.css('[data-testid^="admin-customer-row-"]').map { |row| row["data-testid"] }

    expect(row_ids).to include(
      "admin-customer-row-alex-buyer-example-com",
      "admin-customer-row-jamie-buyer-example-com",
      "admin-customer-row-sage-seller-example-com"
    )

    buyer_row = document.at_css('[data-testid="admin-customer-row-jamie-buyer-example-com"]')
    seller_row = document.at_css('[data-testid="admin-customer-row-sage-seller-example-com"]')

    expect(buyer_row.text).to include("Jamie Buyer", "jamie.buyer@example.com", "0 bookings", "Registered")
    expect(seller_row.text).to include("Sage Seller", "sage.seller@example.com", "0 bookings", "Registered")
    expect(document.at_css('[data-testid="admin-customer-badge-sage-seller-example-com-sale_count"]').text.strip).to eq("1 For Sale")
  end

  it "renders registered timestamps using the user's timezone-aware created_at" do
    user = FactoryBot.create(
      :user,
      first_name: "Zoe",
      last_name: "Bates",
      email: "zoe.bates@example.com",
      mobile_number: "07700 930099"
    )
    user.update_column(:created_at, Time.utc(2026, 4, 21, 12, 20, 47))

    get admin_customers_path

    expect(response).to have_http_status(:ok)

    row = parsed_html.at_css('[data-testid="admin-customer-row-zoe-bates-example-com"]')
    expected_time = "#{I18n.l(user.reload.created_at.in_time_zone, format: :long)} #{user.created_at.in_time_zone.zone}"

    expect(row).to be_present
    expect(row.text).to include("Registered #{expected_time}")
    expect(row.text).not_to include("Registered Tuesday, 21 April 2026 at 12:20 BST")
  end

  it "deduplicates users who already exist as booking customers" do
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
      :user,
      first_name: "Alex",
      last_name: "Buyer",
      email: "alex.buyer@example.com",
      mobile_number: "07700 930010"
    )

    get admin_customers_path

    expect(response).to have_http_status(:ok)
    expect(parsed_html.css('[data-testid="admin-customer-row-alex-buyer-example-com"]').size).to eq(1)
  end

  it "prefers the registered user's current email when older activity still uses a stale address" do
    user = FactoryBot.create(
      :user,
      first_name: "Zoe",
      last_name: "Bates",
      email: "zoe.bates@example.com",
      mobile_number: "07700 930099"
    )
    property = FactoryBot.create(:property)

    FactoryBot.create(
      :appointment,
      :confirmed,
      property: property,
      customer_name: user.full_name,
      customer_email: "zoe.bates@exmaple.com",
      customer_phone: user.mobile_number
    )

    get admin_customers_path, params: { q: "Zoe" }

    expect(response).to have_http_status(:ok)

    document = parsed_html
    row = document.at_css('[data-testid="admin-customer-row-zoe-bates-example-com"]')

    expect(row).to be_present
    expect(row.text).to include("zoe.bates@example.com")
    expect(row.text).not_to include("zoe.bates@exmaple.com")
    expect(document.css('[data-testid^="admin-customer-row-zoe-bates"]').size).to eq(1)
  end

  it "shows a customer profile page with recent bookings" do
    user = FactoryBot.create(
      :user,
      first_name: "Zoe",
      last_name: "Bates",
      email: "zoe.bates@example.com",
      mobile_number: "07700 930099"
    )
    property = FactoryBot.create(:property, address_line_1: "48 Mount Place")
    appointment = FactoryBot.create(
      :appointment,
      :confirmed,
      property:,
      customer_name: user.full_name,
      customer_email: "zoe.bates@exmaple.com",
      customer_phone: user.mobile_number
    )

    get admin_customer_path(user.email)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Customer Zoe Bates")
    expect(response.body).to include("zoe.bates@example.com")
    expect(response.body).to include("Recent bookings")
    expect(response.body).to include(appointment.public_reference)
    expect(response.body).to include("48 Mount Place")

    document = parsed_html
    bookings_link = document.at_css(%(a[href="#{admin_appointments_path(view: "agenda", customer_email: user.email)}"]))
    expect(bookings_link).to be_present
  end

  it "shows a customer profile page for rental applicants without bookings" do
    property = FactoryBot.create(:property, :for_rent, address_line_1: "27 Willow Court")
    rental_application = FactoryBot.create(
      :rental_application,
      property:,
      applicant_name: "Ravi Patel",
      applicant_email: "tenant.ravi.patel@example.com",
      applicant_phone: "07700 905777",
      status: "received"
    )

    get admin_customer_path(rental_application.applicant_email)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Customer Ravi Patel")
    expect(response.body).to include("Recent bookings")

    document = parsed_html
    details = document.css(".detail-list dd").map { |node| node.text.squish }

    expect(document.css(".section-heading > div > p").last.text).to eq("ravi.patel@example.com")
    expect(details).to include("ravi.patel@example.com")
    expect(details).not_to include("tenant.ravi.patel@example.com")
  end

  it "shows role badges for sellers, landlords, buyers with offers, and tenants with approved rental applications" do
    seller = FactoryBot.create(
      :user,
      first_name: "Sky",
      last_name: "Seller",
      email: "sky.seller@example.com",
      mobile_number: "07700 930020"
    )
    landlord = FactoryBot.create(
      :user,
      first_name: "Lane",
      last_name: "Landlord",
      email: "lane.landlord@example.com",
      mobile_number: "07700 930021"
    )
    buyer = FactoryBot.create(
      :user,
      first_name: "Blair",
      last_name: "Buyer",
      email: "blair.buyer@example.com",
      mobile_number: "07700 930022"
    )
    tenant = FactoryBot.create(
      :user,
      first_name: "Toni",
      last_name: "Tenant",
      email: "toni.tenant@example.com",
      mobile_number: "07700 930023"
    )
    dual_role = FactoryBot.create(
      :user,
      first_name: "Drew",
      last_name: "Dual",
      email: "drew.dual@example.com",
      mobile_number: "07700 930024"
    )
    third_party_seller = FactoryBot.create(
      :user,
      first_name: "Parker",
      last_name: "Owner",
      email: "parker.owner@example.com",
      mobile_number: "07700 930025"
    )

    sale_property = FactoryBot.create(:property, user: seller)
    rental_property = FactoryBot.create(:property, :for_rent, user: landlord)
    dual_sale_property = FactoryBot.create(:property, user: dual_role)
    external_sale_property = FactoryBot.create(:property, user: third_party_seller)
    FactoryBot.create(:property, :for_rent, user: dual_role)

    FactoryBot.create(:saved_search, user: buyer, sale_status: Property::SALE_STATUSES[:for_sale])
    FactoryBot.create(:offer, property: sale_property, buyer_email: buyer.email, buyer_name: buyer.full_name, buyer_phone: buyer.mobile_number)
    FactoryBot.create(
      :rental_application,
      property: rental_property,
      applicant_email: tenant.email,
      applicant_name: tenant.full_name,
      applicant_phone: tenant.mobile_number
    )
    FactoryBot.create(
      :rental_application,
      :approved,
      property: rental_property,
      applicant_email: tenant.email,
      applicant_name: tenant.full_name,
      applicant_phone: tenant.mobile_number
    )
    FactoryBot.create(:offer, :accepted, property: external_sale_property, buyer_email: dual_role.email, buyer_name: dual_role.full_name, buyer_phone: dual_role.mobile_number)

    get admin_customers_path

    expect(response).to have_http_status(:ok)

    document = parsed_html

    expect(document.at_css('[data-testid="admin-customer-badge-sky-seller-example-com-sale_count"]')).to be_present
    expect(document.at_css('[data-testid="admin-customer-badge-lane-landlord-example-com-rent_count"]')).to be_present
    expect(document.at_css('[data-testid="admin-customer-badge-blair-buyer-example-com-buyer"]')).to be_present
    expect(document.at_css('[data-testid="admin-customer-badge-toni-tenant-example-com-tenant"]')).to be_present
    expect(document.at_css('[data-testid="admin-customer-badge-drew-dual-example-com-buyer"]')).to be_present
    expect(document.at_css('[data-testid="admin-customer-badge-sky-seller-example-com-seller"]')).not_to be_present
    expect(document.at_css('[data-testid="admin-customer-badge-lane-landlord-example-com-landlord"]')).not_to be_present
    expect(document.at_css('[data-testid="admin-customer-badge-drew-dual-example-com-sale_count"]').text.strip).to eq("1 For Sale")
    expect(document.at_css('[data-testid="admin-customer-badge-drew-dual-example-com-rent_count"]').text.strip).to eq("1 For Rent")
  end

  it "does not show the tenant badge for rental interest without an approved application" do
    landlord = FactoryBot.create(
      :user,
      first_name: "Lane",
      last_name: "Landlord",
      email: "lane.landlord@example.com",
      mobile_number: "07700 930021"
    )
    interested_renter = FactoryBot.create(
      :user,
      first_name: "Iris",
      last_name: "Interest",
      email: "iris.interest@example.com",
      mobile_number: "07700 930031"
    )

    rental_property = FactoryBot.create(:property, :for_rent, user: landlord)
    FactoryBot.create(:saved_property, user: interested_renter, property: rental_property)
    FactoryBot.create(
      :rental_application,
      property: rental_property,
      applicant_email: interested_renter.email,
      applicant_name: interested_renter.full_name,
      applicant_phone: interested_renter.mobile_number,
      status: "received"
    )

    get admin_customers_path

    expect(response).to have_http_status(:ok)
    expect(parsed_html.at_css('[data-testid="admin-customer-badge-iris-interest-example-com-tenant"]')).not_to be_present
  end

  it "does not show the buyer badge for sale interest without an active or completed offer" do
    seller = FactoryBot.create(
      :user,
      first_name: "Sky",
      last_name: "Seller",
      email: "sky.seller@example.com",
      mobile_number: "07700 930020"
    )
    interested_buyer = FactoryBot.create(
      :user,
      first_name: "Bella",
      last_name: "Browse",
      email: "bella.browse@example.com",
      mobile_number: "07700 930032"
    )

    sale_property = FactoryBot.create(:property, user: seller)
    FactoryBot.create(:saved_property, user: interested_buyer, property: sale_property)
    FactoryBot.create(:saved_search, user: interested_buyer, sale_status: Property::SALE_STATUSES[:for_sale])
    FactoryBot.create(
      :appointment,
      :pending,
      property: sale_property,
      customer_name: interested_buyer.full_name,
      customer_email: interested_buyer.email,
      customer_phone: interested_buyer.mobile_number
    )

    get admin_customers_path

    expect(response).to have_http_status(:ok)
    expect(parsed_html.at_css('[data-testid="admin-customer-badge-bella-browse-example-com-buyer"]')).not_to be_present
  end
end
