FactoryBot.define do
  factory :saved_property do
    association :user
    association :property
  end
end
