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

  it "keeps generated availability and appointments on configured open weekdays" do
    availability_windows = generator.availability_windows(
      properties: properties * 3,
      start_day_offset: 3,
      start_time: "09:00",
      duration_minutes: 180,
      cadence_days: 1,
      kind: "open",
      capacity: 1,
      label_prefix: "Generated slot",
      open_weekdays: [1, 2, 3, 4, 5, 6]
    )
    appointments = generator.appointments(
      properties:,
      count: 12,
      assigned_admin_email: "admin@example.com",
      duration_minutes: 60,
      status_cycle: %w[pending confirmed rescheduled completed cancelled no_show],
      start_day_offset: 3,
      start_time: "09:30",
      cadence_hours: 2,
      open_weekdays: [1, 2, 3, 4, 5, 6]
    )

    expect(availability_windows.pluck(:starts_at).map(&:to_date).map(&:cwday)).to all(satisfy { |day| (1..6).cover?(day) })
    expect(appointments.pluck(:requested_time).map(&:to_date).map(&:cwday)).to all(satisfy { |day| (1..6).cover?(day) })
    expect(appointments.pluck(:scheduled_at).map(&:to_date).map(&:cwday)).to all(satisfy { |day| (1..6).cover?(day) })
  end
end
