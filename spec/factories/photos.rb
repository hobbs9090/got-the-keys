FactoryBot.define do
  factory :photo do
    association :property
    sequence(:image_filename) { |n| "listing-photo-#{n}.jpg" }
    sequence(:caption) { |n| "Caption #{n}" }
    sequence(:position)
    primary { false }
  end
end
