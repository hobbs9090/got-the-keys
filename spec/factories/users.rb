FactoryBot.define do
  factory :user do
    first_name { 'Test' }
    last_name { 'User' }
    mobile_number { '07595 123456' }
    language { 'en' }
    terms_of_service { '1' }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'changeme' }
    password_confirmation { 'changeme' }
    admin_provisioned { false }

    trait :admin_provisioned do
      mobile_number { nil }
      admin_provisioned { true }
    end
  end
end
