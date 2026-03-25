FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin#{n}@test.com" }
    language { 'en' }
    password { 'changeme' }
    password_confirmation { 'changeme' }
    # required if the Devise Confirmable module is used
    # confirmed_at Time.now
  end
end
