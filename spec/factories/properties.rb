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
    asking_price { 600_000 }
    featured { false }

    trait :for_rent do
      sale_status { Property::SALE_STATUSES[:for_rent] }
      asking_price { 2_200 }
    end

    trait :featured do
      featured { true }
    end
  end
end
