FactoryBot.define do
  factory :floor_plan do
    association :property
    sequence(:floor_plans) { |n| "floor-plan-#{n}.pdf" }
    sequence(:label) { |n| "Floor plan #{n}" }
    sequence(:position)
  end
end
