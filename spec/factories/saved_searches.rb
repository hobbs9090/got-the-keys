FactoryBot.define do
  factory :saved_search do
    user
    locale { "en" }
    sale_status { Property::SALE_STATUSES[:for_sale] }
    search_query { "Sevenoaks" }
    town_city { "Sevenoaks" }
    min_bedrooms { 3 }
    min_price { 400_000 }
    max_price { 800_000 }
    sort { "recommended" }
    alerts_enabled { true }
  end
end
