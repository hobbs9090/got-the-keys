# frozen_string_literal: true

sale_count = Integer(ENV.fetch("SALE_COUNT", 50))
rent_count = Integer(ENV.fetch("RENT_COUNT", 50))
random = Random.new(20_260_325)

raise ArgumentError, "SALE_COUNT must be positive" if sale_count <= 0
raise ArgumentError, "RENT_COUNT must be positive" if rent_count <= 0

seller_specs = [
  { first_name: "Charlotte", last_name: "Hughes", email: "charlotte.hughes@gmail.example", mobile_number: "07700 901001" },
  { first_name: "Daniel", last_name: "Mercer", email: "daniel.mercer@outlook.example", mobile_number: "07700 901002" },
  { first_name: "Lucy", last_name: "McClure", email: "lucy.mcclure@btinternet.example", mobile_number: "07700 901003" },
  { first_name: "Matthew", last_name: "Wells", email: "matthew.wells@icloud.example", mobile_number: "07700 901004" },
  { first_name: "Grace", last_name: "Turner", email: "grace.turner@gmail.example", mobile_number: "07700 901005" },
  { first_name: "Edward", last_name: "Barrett", email: "edward.barrett@outlook.example", mobile_number: "07700 901006" },
  { first_name: "Sophie", last_name: "Collins", email: "sophie.collins@icloud.example", mobile_number: "07700 901007" },
  { first_name: "James", last_name: "Fletcher", email: "james.fletcher@btinternet.example", mobile_number: "07700 901008" }
].freeze

areas = [
  {
    town_city: "Sevenoaks",
    county: "Kent",
    postcode_districts: %w[TN13 TN14 TN15],
    neighbourhoods: ["Riverhead", "Chipstead", "St Johns", "Dunton Green", "Kippington"],
    nearby: ["Sevenoaks station", "the high street", "Knole Park"],
    sale_ranges: { 2 => 495_000..650_000, 3 => 635_000..845_000, 4 => 825_000..1_125_000, 5 => 1_050_000..1_425_000 },
    rent_ranges: { 2 => 1_850..2_350, 3 => 2_250..2_950, 4 => 2_850..3_650, 5 => 3_450..4_350 }
  },
  {
    town_city: "Westerham",
    county: "Kent",
    postcode_districts: %w[TN16],
    neighbourhoods: ["Crockham Hill", "Brasted", "Valence", "Hosey Hill", "the village edge"],
    nearby: ["the green", "country walks", "local primary schools"],
    sale_ranges: { 2 => 425_000..575_000, 3 => 565_000..745_000, 4 => 715_000..945_000, 5 => 885_000..1_175_000 },
    rent_ranges: { 2 => 1_650..2_150, 3 => 2_050..2_650, 4 => 2_550..3_250, 5 => 3_050..3_850 }
  }
].freeze

street_roots = %w[
  Alder
  Ashdown
  Badger
  Birch
  Bracken
  Cedar
  Charter
  Elm
  Fairmead
  Foxglove
  Gable
  Hazel
  Highfield
  Holly
  Juniper
  Kingswood
  Larkspur
  Lime
  Meadow
  Oakfield
  Orchard
  Paddock
  Parkside
  Quarry
  Rowan
  Sundial
  Willow
  Windmill
  Woodbank
  Yew
].freeze

street_suffixes = %w[
  Close
  Drive
  Gardens
  Grove
  Lane
  Mews
  Place
  Rise
  Road
  Vale
].freeze

sale_property_types = [
  "Detached house",
  "Semi-detached house",
  "End-of-terrace house",
  "Townhouse",
  "Terraced house",
  "Cottage"
].freeze

rent_property_types = [
  "Detached house",
  "Semi-detached house",
  "Townhouse",
  "Terraced house",
  "Cottage"
].freeze

shared_features = [
  "a bright kitchen diner",
  "a generous rear garden",
  "a separate utility room",
  "a comfortable sitting room",
  "good built-in storage",
  "a study for home working",
  "off-street parking",
  "a principal bedroom with fitted wardrobes"
].freeze

POSTCODE_LETTERS = %w[A B D E F G H J L N P R S T U W X Y Z].freeze

address_pool =
  street_roots.product(street_suffixes).shuffle(random: random).each_with_index.map do |(root, suffix), index|
    number = 4 + (index * 2)
    "#{number} #{root} #{suffix}"
  end

required_count = sale_count + rent_count
raise "Not enough unique addresses for #{required_count} listings" if address_pool.size < required_count

def price_for(area:, sale_status:, bedrooms:, random:)
  ranges = sale_status == "For Sale" ? area.fetch(:sale_ranges) : area.fetch(:rent_ranges)
  range = ranges.fetch(bedrooms)
  candidate = range.begin + random.rand(range.end - range.begin + 1)

  if sale_status == "For Sale"
    (candidate / 5_000.0).round * 5_000
  else
    (candidate / 25.0).round * 25
  end
end

def postcode_for(area:, random:, index:)
  district = area.fetch(:postcode_districts).fetch(index % area.fetch(:postcode_districts).length)
  sector = 1 + ((index + random.rand(4)) % 9)
  inward = "#{POSTCODE_LETTERS.fetch((index + 3) % POSTCODE_LETTERS.length)}#{POSTCODE_LETTERS.fetch((index + 11) % POSTCODE_LETTERS.length)}"
  "#{district} #{sector}#{inward}"
end

def description_for(property_type:, sale_status:, area:, bedrooms:, features:)
  bedroom_label = "#{bedrooms}-bedroom"
  nearby = area.fetch(:nearby)

  if sale_status == "For Sale"
    "A well-presented #{bedroom_label} #{property_type.downcase} in #{area.fetch(:town_city)} with #{features[0]}, #{features[1]}, and #{features[2]}. " \
      "The home is set on a made-up residential address convenient for #{nearby.first} and #{nearby.last}, and should suit buyers who want practical space with a polished finish."
  else
    "A well-kept #{bedroom_label} #{property_type.downcase} in #{area.fetch(:town_city)} offering #{features[0]}, #{features[1]}, and #{features[2]}. " \
      "It is handy for #{nearby.first} and #{nearby.last}, making it a strong rental option for tenants who want a straightforward move into the Sevenoaks and Westerham area."
  end
end

def tagline_for(property_type:, sale_status:, area:, feature:)
  market_phrase = sale_status == "For Sale" ? "buyers" : "renters"
  "#{property_type} for #{market_phrase} near #{area.fetch(:nearby).first} with #{feature.sub(/\Aa /, '')}"
end

def bedrooms_for(sale_status:, random:)
  weighted =
    if sale_status == "For Sale"
      [[2, 2], [3, 4], [4, 3], [5, 1]]
    else
      [[2, 3], [3, 4], [4, 2], [5, 1]]
    end

  roll = random.rand(weighted.sum(&:last))
  weighted.each do |value, weight|
    return value if roll < weight

    roll -= weight
  end

  weighted.last.first
end

def bathrooms_for(bedrooms)
  [[1, bedrooms - 1].max, 3].min
end

owners =
  seller_specs.map do |attributes|
    user = User.find_or_initialize_by(email: attributes.fetch(:email))
    user.assign_attributes(
      first_name: attributes.fetch(:first_name),
      last_name: attributes.fetch(:last_name),
      mobile_number: attributes.fetch(:mobile_number),
      language: "en",
      password: "secret",
      password_confirmation: "secret",
      terms_of_service: true
    )
    user.save!
    user
  end

ActiveRecord::Base.transaction do
  NotificationLog.delete_all
  AppointmentEvent.delete_all
  Appointment.delete_all
  AvailabilityWindow.delete_all
  ViewingTime.delete_all
  Photo.delete_all
  FloorPlan.delete_all
  Property.delete_all
  User.update_all(properties_count: 0)

  listings = [
    *Array.new(sale_count, "For Sale"),
    *Array.new(rent_count, "For Rent")
  ].shuffle(random: random)

  listings.each_with_index do |sale_status, index|
    area = areas.fetch(index % areas.length)
    bedrooms = bedrooms_for(sale_status:, random:)
    property_type =
      if sale_status == "For Sale"
        sale_property_types.fetch(index % sale_property_types.length)
      else
        rent_property_types.fetch(index % rent_property_types.length)
      end
    features = shared_features.sample(3, random: random)
    owner = owners.fetch(index % owners.length)
    address_line_1 = address_pool.fetch(index)
    address_line_2 = index.even? ? area.fetch(:neighbourhoods).fetch((index / 2) % area.fetch(:neighbourhoods).length) : ""

    owner.properties.create!(
      address_line_1: address_line_1,
      address_line_2: address_line_2,
      town_city: area.fetch(:town_city),
      county: area.fetch(:county),
      postcode: postcode_for(area:, random:, index:),
      country: "United Kingdom",
      property_type: property_type,
      listing_tagline: tagline_for(property_type:, sale_status:, area:, feature: features.first),
      property_description: description_for(property_type:, sale_status:, area:, bedrooms:, features:),
      bedrooms: bedrooms,
      bathrooms: bathrooms_for(bedrooms),
      sale_status: sale_status,
      asking_price: price_for(area:, sale_status:, bedrooms:, random:),
      featured: (index % 9).zero?,
      created_at: Time.current - (index % 45).days,
      updated_at: Time.current - (index % 12).days
    )
  end

  BookingConfiguration.current.update!(
    active_demo_scenario_key: "custom_sevenoaks_westerham_catalogue",
    last_demo_data_action_at: Time.current
  )
end

Rails.cache.clear

puts({
  properties: Property.count,
  for_sale: Property.for_sale.count,
  for_rent: Property.for_rent.count,
  towns: Property.group(:town_city).count,
  owners_used: Property.distinct.count(:user_id)
}.inspect)
