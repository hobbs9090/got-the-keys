require "rails_helper"
require "fileutils"

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
    expect(baseline[:photo_count]).to eq(102)
    expect(baseline[:property_document_count]).to eq(2)
  end

  it "applies a scenario and records the active key" do
    summary = loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com")

    expect(summary[:property_count]).to eq(100)
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
    expect(Admin.count).to eq(3)
    expect(Admin.pluck(:email)).to match_array([
      "steven@gotthekeys.uk",
      "kate@gotthekeys.uk",
      "inarra@gotthekeys.uk"
    ])
    expect(Admin.find_by!(email: "steven@gotthekeys.uk").valid_password?("secret1234")).to be(true)
    expect(User.count).to eq(92)
    expect(Property.count).to eq(100)
    expect(Property.for_sale.count).to eq(40)
    expect(Property.for_rent.count).to eq(60)
    expect(Property.publicly_visible.for_sale.count).to eq(40)
    expect(Property.publicly_visible.for_rent.count).to eq(60)
    expect(User.where("properties_count > 0").count).to eq(88)
    expect(User.where(properties_count: 1).count).to eq(81)
    expect(Property.where.not(year_built: nil).count).to eq(100)
    expect(Photo.count).to eq(102)
    expect(FloorPlan.count).to eq(2)
    expect(PropertyDocument.count).to eq(2)
    expect(AvailabilityWindow.count).to eq(100)
    expect(Appointment.count).to eq(40)
    expect(Enquiry.count).to eq(40)
    expect(Offer.count).to eq(10)
    expect(RentalApplication.count).to eq(14)
    expect(User.pluck(:language).uniq).to match_array(%w[de en fr it zh])
    expect(User.order(:email).pluck(:email)).to include(
      "alex.cole@example.com",
      "hans.schmidt@example.com",
      "jean.dupont@example.com",
      "wei.zhang@example.com",
      "mario.rossi@example.com",
      "nina.hughes@example.com",
      "amelia.hart@example.com",
      "holly.wade@example.com",
      "finn.chapman@example.com",
      "logan.kemp@example.com",
      "sam.turner@example.com",
    )
    expect(User.find_by!(email: "nina.hughes@example.com").valid_password?("secret1234")).to be(true)
    expect(User.find_by!(email: "amelia.hart@example.com").slice(:first_name, :last_name)).to eq(
      "first_name" => "Amelia",
      "last_name" => "Hart"
    )
    expect(User.find_by!(email: "logan.kemp@example.com").slice(:first_name, :last_name)).to eq(
      "first_name" => "Logan",
      "last_name" => "Kemp"
    )
    expect(User.where("first_name LIKE 'Owner%' OR last_name LIKE 'Seed%'")).to be_empty

    sale_owner_listing_counts = Property.for_sale.group(:user_id).count.values.sort
    rental_owner_listing_counts = Property.for_rent.group(:user_id).count.values.sort

    expect(sale_owner_listing_counts.count(1)).to eq(33)
    expect(sale_owner_listing_counts.count(2)).to eq(2)
    expect(sale_owner_listing_counts.count(3)).to eq(1)
    expect(sale_owner_listing_counts.uniq).to eq([1, 2, 3])

    expect(rental_owner_listing_counts.count(1)).to eq(49)
    expect(rental_owner_listing_counts.count(2)).to eq(2)
    expect(rental_owner_listing_counts.count(3)).to eq(1)
    expect(rental_owner_listing_counts.count(4)).to eq(1)
    expect(rental_owner_listing_counts.uniq).to eq([1, 2, 3, 4])

    shared_owner = User.find_by!(email: "logan.kemp@example.com")
    expect(shared_owner.properties.for_sale.count).to eq(1)
    expect(shared_owner.properties.for_rent.count).to eq(4)
    expect(Property.find_by!(address_line_1: "18 Cedar Road").available_from).to eq(Date.new(2026, 4, 15))
    expect(Property.find_by!(address_line_1: "Flat 3, 44 Mount Ephraim").available_from).to eq(Date.new(2026, 5, 1))
    expect(Property.find_by!(address_line_1: "Apartment 11, 9 Park Lane").available_from).to eq(Date.new(2026, 4, 25))
    expect(RentalApplication.minimum(:move_in_date)).to be >= Date.new(2026, 4, 15)
    expect(BookingConfiguration.current.lead_time_hours).to eq(0)

    seeded_houses = Property.where(property_type: "House")
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
    expect(AvailabilityWindow.pluck(:starts_at).map(&:to_date).map(&:cwday)).to all(satisfy { |day| (1..6).cover?(day) })
    expect(AvailabilityWindow.pluck(:ends_at).map(&:to_date).map(&:cwday)).to all(satisfy { |day| (1..6).cover?(day) })
    expect(Appointment.pluck(:requested_time).map(&:to_date).map(&:cwday)).to all(satisfy { |day| (1..6).cover?(day) })
    expect(Appointment.pluck(:scheduled_at).map(&:to_date).map(&:cwday)).to all(satisfy { |day| (1..6).cover?(day) })

    current_appointments = Appointment.where(status: %w[pending confirmed rescheduled]).where(scheduled_at: Time.current...(Time.current + 1.hour))
    completed_appointments = Appointment.where(status: "completed").where("scheduled_at < ?", Time.current)
    upcoming_appointments = Appointment.where(status: %w[pending confirmed rescheduled]).order(:scheduled_at)
    next_three_open_days = [Date.new(2026, 4, 1), Date.new(2026, 4, 2), Date.new(2026, 4, 3)]

    expect(current_appointments.count).to be >= 2
    expect(completed_appointments.count).to be >= 4
    expect(upcoming_appointments.limit(12).pluck(:scheduled_at).map(&:to_date).uniq).to all(be_in(next_three_open_days))
    expect(upcoming_appointments.where("scheduled_at < ?", Time.zone.local(2026, 4, 3, 13, 0)).count).to be >= 8
    expect(AvailabilityWindow.where("starts_at <= ?", Time.zone.local(2026, 4, 3, 23, 59, 59)).count).to be >= 4
  end

  it "exports the current dataset as YAML" do
    loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com")
    exported = loader.export

    expect(exported).to include("Exported Snapshot")
    expect(exported).to include("baseline")
    expect(exported).to include("steven@gotthekeys.uk")
    expect(exported).to include("kate@gotthekeys.uk")
    expect(exported).to include("inarra@gotthekeys.uk")
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

  it "clears dependent records before removing users and properties during a reset" do
    owner = FactoryBot.create(:user, email: "owner@example.com")
    saver = FactoryBot.create(:user, email: "saver@example.com")
    property = FactoryBot.create(:property, user: owner)
    FactoryBot.create(:api_refresh_token, user: saver)
    FactoryBot.create(:saved_property, user: saver, property:)
    SavedSearch.create!(user: saver, locale: "en", email: saver.email, alerts_enabled: true, search_query: "Sevenoaks")
    ViewingTime.create!(
      property:,
      start_time: Time.zone.local(2026, 4, 2, 10, 0),
      end_time: Time.zone.local(2026, 4, 2, 11, 0)
    )

    expect { loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com") }
      .to change(SavedProperty, :count)
      .from(1)
      .to(0)
      .and change(SavedSearch, :count)
      .from(1)
      .to(0)
      .and change(ApiRefreshToken, :count)
      .from(1)
      .to(0)
      .and change(ViewingTime, :count)
      .from(1)
      .to(0)
  end

  it "auto-attaches supplementary property images that follow the hero naming convention" do
    hero_filename = "properties/property_21_market_lane_hero.webp"
    supplementary_filenames = [
      "properties/property_21_market_lane_supp_1.webp",
      "properties/property_21_market_lane_supp_2.webp"
    ]
    asset_root = Rails.root.join("app/assets/images/properties")
    created_paths = supplementary_filenames.map { |filename| asset_root.join(File.basename(filename)) }

    created_paths.each do |path|
      FileUtils.mkdir_p(path.dirname)
      File.binwrite(path, "supplementary-image")
    end

    loader.apply_yaml!(yaml_source: <<~YAML, actor_email: "spec@example.com")
      key: supplementary-demo
      name: Supplementary Demo
      description: Verifies supplementary image discovery.
      booking_configuration:
        slot_duration_minutes: 60
        lead_time_hours: 4
        buffer_minutes: 15
        office_opens_at: "09:00"
        office_closes_at: "18:00"
        open_weekdays: [1, 2, 3, 4, 5]
      admins:
        - email: admin@example.com
          password: secret1234
          password_confirmation: secret1234
          language: en
      users:
        - first_name: Casey
          last_name: Hart
          mobile_number: "07700 900250"
          email: casey.hart@example.com
          password: secret1234
          password_confirmation: secret1234
          language: en
      properties:
        - key: supplementary_home
          owner_email: casey.hart@example.com
          address_line_1: 21 Market Lane
          address_line_2:
          town_city: Sevenoaks
          county: Kent
          postcode: TN13 1AA
          country: United Kingdom
          property_type: House
          listing_tagline: Bright family house near the high street
          property_description: A polished family house with a bright kitchen, generous reception rooms, and a landscaped garden.
          listing_state: published
          sale_status: For Sale
          furnished_state: unfurnished
          featured: false
          bedrooms: 3
          bathrooms: 2
          asking_price: 650000
          created_at: 2026-04-01 09:00:00 Z
          updated_at: 2026-04-01 09:00:00 Z
      photos:
        - property_key: supplementary_home
          image_filename: #{hero_filename}
          caption: Front exterior
          position: 1
          primary: true
      floor_plans: []
      property_documents: []
      availability_windows: []
      appointments: []
      enquiries: []
      offers: []
      rental_applications: []
      qa:
        family: happy_path
        intended_journey: Supplementary image discovery
        complexity: foundational
        risk_type: workflow
        locale_coverage: [en]
        quick_reset: false
    YAML

    photos = Property.find_by!(address_line_1: "21 Market Lane").photos.ordered

    expect(photos.pluck(:image_filename)).to eq([
      hero_filename,
      *supplementary_filenames
    ])
    expect(photos.pluck(:primary)).to eq([true, false, false])
    expect(photos.pluck(:position)).to eq([1, 2, 3])
    expect(photos.pluck(:caption)).to eq([
      "Front exterior",
      "Supplementary image 1",
      "Supplementary image 2"
    ])
  ensure
    created_paths&.each { |path| FileUtils.rm_f(path) }
  end
end
