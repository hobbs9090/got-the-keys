FactoryBot.define do
  factory :rental_application do
    association :property, factory: [:property, :for_rent]
    admin { nil }
    sequence(:applicant_name) { |n| "Applicant #{n}" }
    sequence(:applicant_email) { |n| "applicant#{n}@example.com" }
    sequence(:applicant_phone) { |n| format("07700 96%04d", n) }
    move_in_date { Date.current + 21.days }
    status { "received" }
    guarantor_required { false }
    guarantor_available { false }
    affordability_notes { "Permanent employment and strong affordability." }
    notes { "Can move quickly if needed." }
    internal_notes { nil }

    trait :approved do
      status { "approved" }
    end

    trait :rejected do
      status { "rejected" }
    end
  end
end
