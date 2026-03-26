FactoryBot.define do
  factory :property_document do
    association :property
    sequence(:title) { |n| "Document #{n}" }
    sequence(:file_name) { |n| "document-#{n}.pdf" }
    category { "brochure" }
    visibility { "public" }
    sequence(:position) { |n| n }

    trait :private_document do
      visibility { "private" }
    end
  end
end
