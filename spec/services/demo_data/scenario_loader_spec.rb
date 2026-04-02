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
    lifecycle = previews.find { |scenario| scenario[:key] == "listing_lifecycle" }
    leads = previews.find { |scenario| scenario[:key] == "lead_management" }
    viewing = previews.find { |scenario| scenario[:key] == "viewing_operations" }
    deals = previews.find { |scenario| scenario[:key] == "deal_progression" }
    documents = previews.find { |scenario| scenario[:key] == "documents_and_trust" }

    expect(previews.map { |scenario| scenario[:key] }).to include("baseline", "fully_booked_day", "qa_edge_cases", "high_volume_search", "listing_lifecycle", "lead_management", "viewing_operations", "deal_progression", "documents_and_trust")
    expect(baseline[:property_count]).to eq(100)
    expect(baseline[:availability_window_count]).to eq(100)
    expect(baseline[:appointment_count]).to eq(40)
    expect(baseline[:enquiry_count]).to eq(40)
    expect(baseline[:offer_count]).to eq(10)
    expect(baseline[:rental_application_count]).to eq(14)
    expect(baseline[:photo_count]).to eq(11)
    expect(baseline[:property_document_count]).to eq(2)
    expect(lifecycle[:property_count]).to eq(5)
    expect(lifecycle[:photo_count]).to eq(3)
    expect(lifecycle[:floor_plan_count]).to eq(2)
    expect(leads[:enquiry_count]).to eq(5)
    expect(leads[:enquiry_statuses]).to include("new" => 2, "contacted" => 1, "qualified" => 1, "unqualified" => 1)
    expect(viewing[:appointment_statuses]).to include("confirmed" => 1, "rescheduled" => 1, "completed" => 1, "no_show" => 1)
    expect(deals[:offer_statuses]).to include("rejected" => 1, "withdrawn" => 1, "accepted" => 1)
    expect(deals[:rental_application_statuses]).to include("rejected" => 1, "withdrawn" => 1, "approved" => 1)
    expect(documents[:property_document_count]).to eq(2)
    expect(documents.dig(:qa, :family)).to eq("accessibility")
    expect(viewing.dig(:qa, :quick_reset)).to eq(true)
  end

  it "applies a scenario and records the active key" do
    summary = loader.apply_catalog!(key: "baseline", actor_email: "spec@example.com")

    expect(summary[:property_count]).to eq(100)
    expect(BookingConfiguration.current.active_demo_scenario_key).to eq("baseline")
    expect(Admin.count).to eq(1)
    expect(Admin.pluck(:email)).to eq(["steven@gotthekeys.uk"])
    expect(User.count).to eq(4)
    expect(Property.count).to eq(100)
    expect(Property.for_sale.count).to eq(40)
    expect(Property.for_rent.count).to eq(60)
    expect(Property.publicly_visible.for_sale.count).to eq(40)
    expect(Property.publicly_visible.for_rent.count).to eq(60)
    expect(Property.where.not(year_built: nil).count).to eq(100)
    expect(Photo.count).to eq(11)
    expect(FloorPlan.count).to eq(2)
    expect(PropertyDocument.count).to eq(2)
    expect(AvailabilityWindow.count).to eq(100)
    expect(Appointment.count).to eq(40)
    expect(Enquiry.count).to eq(40)
    expect(Offer.count).to eq(10)
    expect(RentalApplication.count).to eq(14)
    expect(User.pluck(:language).uniq).to eq(["en"])
    expect(User.order(:email).pluck(:email)).to match_array([
      "charlotte.hughes@example.com",
      "daniel.mercer@example.com",
      "lucy.mcclure@example.com",
      "matthew.wells@example.com"
    ])
    expect(Property.find_by!(address_line_1: "18 Cedar Road").available_from).to eq(Date.new(2026, 4, 15))
    expect(Property.find_by!(address_line_1: "Flat 3, 44 Mount Ephraim").available_from).to eq(Date.new(2026, 5, 1))
    expect(Property.find_by!(address_line_1: "Apartment 11, 9 Park Lane").available_from).to eq(Date.new(2026, 4, 25))
    expect(RentalApplication.minimum(:move_in_date)).to be >= Date.new(2026, 4, 15)

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
end
