FactoryBot.define do
  factory :booking_configuration do
    slot_duration_minutes { 45 }
    lead_time_hours { 4 }
    buffer_minutes { 15 }
    office_opens_at { "09:00" }
    office_closes_at { "17:00" }
    open_weekdays { %w[1 2 3 4 5] }
    active_demo_scenario_key { "baseline" }
  end
end
