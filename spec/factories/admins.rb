FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin#{n}@test.com" }
    language { 'en' }
    password { 'changeme123' }
    password_confirmation { 'changeme123' }
    # required if the Devise Confirmable module is used
    # confirmed_at Time.now
  end
end
