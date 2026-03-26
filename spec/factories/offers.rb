FactoryBot.define do
  factory :offer do
    association :property
    admin { nil }
    sequence(:buyer_name) { |n| "Buyer #{n}" }
    sequence(:buyer_email) { |n| "buyer#{n}@example.com" }
    sequence(:buyer_phone) { |n| format("07700 95%04d", n) }
    amount { 500_000 }
    status { "received" }
    chain_position { "Mortgage agreed in principle" }
    notes { "Ready to move quickly." }
    internal_notes { nil }

    trait :accepted do
      status { "accepted" }
    end

    trait :rejected do
      status { "rejected" }
    end
  end
end
