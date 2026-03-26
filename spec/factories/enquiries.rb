FactoryBot.define do
  factory :enquiry do
    association :property
    admin { nil }
    sequence(:customer_name) { |n| "Lead #{n}" }
    sequence(:customer_email) { |n| "lead#{n}@example.com" }
    sequence(:customer_phone) { |n| format("07700 94%04d", n) }
    source_type { "general_enquiry" }
    message { "I would like more information about the property, local schools, and next steps for arranging a viewing." }
    status { "new" }
    internal_notes { nil }
    spam { false }
    spam_reason { nil }

    trait :contacted do
      status { "contacted" }
      contacted_at { Time.current }
    end

    trait :qualified do
      status { "qualified" }
    end

    trait :unqualified do
      status { "unqualified" }
    end

    trait :spam do
      customer_email { "growth@mailinator.com" }
      message { "We can improve backlinks and crypto SEO. Visit https://spam.example.test and https://spam2.example.test now." }
      spam { true }
      spam_reason { "Potential spam" }
    end
  end
end
