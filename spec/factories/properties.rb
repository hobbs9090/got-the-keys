FactoryBot.define do
  factory :property do
    association :user
    sequence(:address_line_1) { |n| "#{n} Market Street" }
    address_line_2 { "Buckham Thorns Road" }
    town_city { "Westerham" }
    county { "Kent" }
    postcode { "TN16 1ET" }
    country { "United Kingdom" }
    property_type { "House" }
    listing_tagline { "Light-filled family home" }
    property_description { "A bright detached family home with generous living space, practical storage, and a private garden." }
    bedrooms { 4 }
    bathrooms { 2 }
    sale_status { Property::SALE_STATUSES[:for_sale] }
    listing_state { "published" }
    asking_price { 600_000 }
    featured { false }
    tenure { "Freehold" }
    council_tax_band { "F" }
    furnishing { "Unfurnished" }
    available_from { Date.current + 14.days }
    year_built { 1998 }
    refurbished_year { 2022 }
    parking { "Driveway" }
    outdoor_space { "Rear garden" }
    floor_area_sq_ft { 1_450 }
    pets_allowed { true }

    trait :for_rent do
      sale_status { Property::SALE_STATUSES[:for_rent] }
      asking_price { 2_200 }
      furnishing { "Part furnished" }
      deposit_amount { 2_500 }
      year_built { 2012 }
      refurbished_year { 2024 }
    end

    trait :featured do
      featured { true }
    end

    trait :draft do
      listing_state { "draft" }
    end

    trait :review_pending do
      listing_state { "review_pending" }
    end
  end
end
