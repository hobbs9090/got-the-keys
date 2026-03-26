FactoryBot.define do
  factory :appointment do
    association :property
    admin { nil }
    sequence(:customer_name) { |n| "Viewer #{n}" }
    sequence(:customer_email) { |n| "viewer#{n}@example.com" }
    sequence(:customer_phone) { |n| format("07700 93%04d", n) }
    transient do
      requested_hour { 10 }
      requested_minutes { 0 }
    end
    requested_time do
      BookingTimeHelpers.next_booking_slot(hour: requested_hour, minutes: requested_minutes)
    end
    scheduled_at { requested_time }
    duration_minutes { BookingConfiguration.current.slot_duration_minutes }
    status { "pending" }
    notes { "Please confirm parking arrangements." }
    internal_notes { nil }

    trait :pending do
      status { "pending" }
    end

    trait :confirmed do
      status { "confirmed" }
    end

    trait :rescheduled do
      status { "rescheduled" }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :completed do
      status { "completed" }
    end

    trait :no_show do
      status { "no_show" }
    end

    trait :assigned do
      association :admin
    end
  end
end
