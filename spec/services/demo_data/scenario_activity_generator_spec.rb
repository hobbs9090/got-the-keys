require "rails_helper"

RSpec.describe DemoData::ScenarioActivityGenerator do
  include ActiveSupport::Testing::TimeHelpers

  let(:generator) { described_class.new }
  let(:properties) do
    [
      { key: "baseline_rental_001", town_city: "Croydon", property_type: "Flat", asking_price: 1950 }
    ]
  end

  around do |example|
    travel_to(Time.zone.local(2026, 4, 1, 9, 0)) { example.run }
  end

  it "generates no-show appointments safely in the past" do
    appointments = generator.appointments(
      properties:,
      count: 8,
      assigned_admin_email: "admin@example.com",
      duration_minutes: 45,
      status_cycle: %w[pending confirmed completed no_show],
      start_day_offset: 9,
      start_time: "09:30",
      cadence_hours: 2
    )

    no_show_appointments = appointments.select { |appointment| appointment[:status] == "no_show" }

    expect(no_show_appointments).not_to be_empty
    expect(no_show_appointments).to all(satisfy { |appointment| appointment[:scheduled_at] < Time.current })
  end
end
