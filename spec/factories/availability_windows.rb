FactoryBot.define do
  factory :availability_window do
    association :property
    kind { "open" }
    starts_at { BookingTimeHelpers.booking_time_on(Date.current + 1.day, hour: 10) }
    ends_at { starts_at + 1.hour }
    label { kind == "open" ? "Morning slot" : "Unavailable" }
    notes { "Managed through the booking desk." }

    trait :blackout do
      kind { "blackout" }
      label { "Maintenance blackout" }
    end
  end
end
