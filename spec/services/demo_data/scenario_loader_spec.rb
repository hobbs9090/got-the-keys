require "rails_helper"

RSpec.describe DemoData::ScenarioLoader do
  include ActiveSupport::Testing::TimeHelpers

  subject(:loader) { described_class.new }

  around do |example|
    travel_to(Time.zone.local(2026, 4, 1, 9, 0)) { example.run }
  end

  before do
    ActionMailer::Base.deliveries.clear if defined?(ActionMailer::Base)
  end

  it "previews the bundled scenarios" do
    previews = loader.scenarios
    baseline = previews.find { |scenario| scenario[:key] == "baseline" }

    expect(previews.map { |scenario| scenario[:key] }).to eq(["baseline"])
    expect(baseline[:property_count]).to eq(100)
    expect(baseline[:availability_window_count]).to eq(100)
    expect(baseline[:appointment_count]).to eq(40)
    expect(baseline[:enquiry_count]).to eq(40)
    expect(baseline[:offer_count]).to eq(10)
    expect(baseline[:rental_application_count]).to eq(14)
    expect(baseline[:photo_count]).to eq(100)
    expect(baseline[:property_document_count]).to eq(2)
  end

  it "applies a scenario and records the active key" do
    summary = loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com")

    expect(summary[:property_count]).to eq(100)
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
    expect(Admin.count).to eq(2)
    expect(Admin.pluck(:email)).to match_array(["steven@gotthekeys.uk", "kate@gotthekeys.uk"])
    expect(User.count).to eq(7)
    expect(Property.count).to eq(100)
    expect(Property.for_sale.count).to eq(40)
    expect(Property.for_rent.count).to eq(60)
    expect(Property.publicly_visible.for_sale.count).to eq(40)
    expect(Property.publicly_visible.for_rent.count).to eq(60)
    expect(Property.where.not(year_built: nil).count).to eq(100)
    expect(Photo.count).to eq(100)
    expect(FloorPlan.count).to eq(2)
    expect(PropertyDocument.count).to eq(2)
    expect(AvailabilityWindow.count).to eq(100)
    expect(Appointment.count).to eq(40)
    expect(Enquiry.count).to eq(40)
    expect(Offer.count).to eq(10)
    expect(RentalApplication.count).to eq(14)
    expect(User.pluck(:language).uniq).to eq(["en"])
    expect(User.order(:email).pluck(:email)).to match_array([
      "alex.cole@example.com",
      "charlotte.hughes@example.com",
      "daniel.mercer@example.com",
      "lucy.mcclure@example.com",
      "matthew.wells@example.com",
      "nina.hughes@example.com",
      "sam.turner@example.com"
    ])
    expect(Property.find_by!(address_line_1: "18 Cedar Road").available_from).to eq(Date.new(2026, 4, 15))
    expect(Property.find_by!(address_line_1: "Flat 3, 44 Mount Ephraim").available_from).to eq(Date.new(2026, 5, 1))
    expect(Property.find_by!(address_line_1: "Apartment 11, 9 Park Lane").available_from).to eq(Date.new(2026, 4, 25))
    expect(RentalApplication.minimum(:move_in_date)).to be >= Date.new(2026, 4, 15)

    seeded_houses = Property.where(
      "lower(property_type) LIKE ? OR lower(property_type) LIKE ? OR lower(property_type) = ?",
      "%house%",
      "%terrace%",
      "townhouse"
    )
    family_houses = seeded_houses.where(bedrooms: 3..5)
    most_expensive_house = seeded_houses.order(asking_price: :desc).first

    expect(family_houses.where(bathrooms: 2).count).to eq(23)
    expect(seeded_houses.where(bathrooms: 3).count).to eq(2)
    expect(most_expensive_house.bedrooms).to eq(6)

    baseline_enquiry = Enquiry.find_by!(customer_email: "emily.carter@example.com")
    expect(baseline_enquiry.created_at).to eq(Time.zone.local(2026, 3, 31, 9, 15))
    expect(baseline_enquiry.updated_at).to eq(Time.zone.local(2026, 3, 31, 9, 15))
    expect(baseline_enquiry.audit_logs.order(:id).pluck(:occurred_at)).to eq([Time.zone.local(2026, 3, 31, 9, 15)])

    contacted_enquiry = Enquiry.find_by!(customer_email: "leon.grant@example.com")
    expect(contacted_enquiry.created_at).to eq(Time.zone.local(2026, 3, 28, 11, 20))
    expect(contacted_enquiry.updated_at).to eq(Time.zone.local(2026, 3, 29, 15, 45))

    accepted_offer = Offer.find_by!(status: "accepted")
    expect(accepted_offer.created_at).to be < accepted_offer.updated_at
    expect(accepted_offer.timeline.order(:occurred_at).pluck(:occurred_at)).to eq([accepted_offer.created_at, accepted_offer.updated_at])

    approved_application = RentalApplication.find_by!(status: "approved")
    expect(approved_application.created_at).to be < approved_application.updated_at
    expect(approved_application.timeline.order(:occurred_at).pluck(:occurred_at)).to eq([approved_application.created_at, approved_application.updated_at])
    expect(approved_application.move_in_date).to be >= approved_application.created_at.to_date + 12.days
  end

  it "exports the current dataset as YAML" do
    loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com")
    exported = loader.export

    expect(exported).to include("Exported Snapshot")
    expect(exported).to include("baseline")
    expect(exported).to include("steven@gotthekeys.uk")
    expect(exported).to include("kate@gotthekeys.uk")
    expect(exported).to include("photos:")
    expect(exported).to include("listing_state:")
    expect(exported).to include("enquiries:")
    expect(exported).to include("visit_outcome:")
    expect(exported).to include("offers:")
    expect(exported).to include("rental_applications:")
    expect(exported).to include("property_documents:")
    expect(exported).to include("year_built:")
    expect(exported).to include("refurbished_year:")
    expect(exported).to include("created_at:")
    expect(exported).to include("updated_at:")
    expect(exported).to include("qa:")
  end

  it "clears saved properties and saved searches before removing users and properties during a reset" do
    owner = FactoryBot.create(:user, email: "owner@example.com")
    saver = FactoryBot.create(:user, email: "saver@example.com")
    property = FactoryBot.create(:property, user: owner)
    FactoryBot.create(:saved_property, user: saver, property:)
    SavedSearch.create!(user: saver, locale: "en", email: saver.email, alerts_enabled: true, search_query: "Sevenoaks")

    expect { loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com") }
      .to change(SavedProperty, :count)
      .from(1)
      .to(0)
      .and change(SavedSearch, :count)
      .from(1)
      .to(0)
  end
end
