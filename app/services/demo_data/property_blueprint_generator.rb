module DemoData
  class PropertyBlueprintGenerator
    AREA_CATALOG = [
      {
        town_city: 'Sevenoaks',
        county: 'Kent',
        postcode_districts: %w[TN13 TN14 TN15],
        sale_range: 425_000..1_350_000,
        rent_range: 1_550..3_950,
        nearby: ['Sevenoaks station', 'the high street', 'Knole Park'],
        neighbourhoods: ['Riverhead', 'St Johns', 'Chipstead']
      },
      {
        town_city: 'Tunbridge Wells',
        county: 'Kent',
        postcode_districts: %w[TN1 TN2 TN4],
        sale_range: 315_000..975_000,
        rent_range: 1_250..3_200,
        nearby: ['the Pantiles', 'mainline rail links', 'good local schools'],
        neighbourhoods: ['Southborough', 'St Johns', 'Mount Ephraim']
      },
      {
        town_city: 'Canterbury',
        county: 'Kent',
        postcode_districts: %w[CT1 CT2 CT3],
        sale_range: 265_000..780_000,
        rent_range: 1_050..2_750,
        nearby: ['the city centre', 'Canterbury West', 'the university quarter'],
        neighbourhoods: ['St Dunstans', 'Wincheap', 'Harbledown']
      },
      {
        town_city: 'Bromley',
        county: 'Greater London',
        postcode_districts: %w[BR1 BR2 BR3],
        sale_range: 365_000..1_150_000,
        rent_range: 1_400..3_650,
        nearby: ['Bromley South', 'the Glades', 'local parkland'],
        neighbourhoods: ['Shortlands', 'Bickley', 'Sundridge Park']
      },
      {
        town_city: 'Croydon',
        county: 'Greater London',
        postcode_districts: %w[CR0 CR2 CR8],
        sale_range: 245_000..785_000,
        rent_range: 1_150..2_950,
        nearby: ['East Croydon', 'tram connections', 'restaurant and retail options'],
        neighbourhoods: ['South Croydon', 'Addiscombe', 'Sanderstead']
      },
      {
        town_city: 'Guildford',
        county: 'Surrey',
        postcode_districts: %w[GU1 GU2 GU4],
        sale_range: 395_000..1_250_000,
        rent_range: 1_450..3_850,
        nearby: ['Guildford station', 'the town centre', 'the Surrey Hills'],
        neighbourhoods: ['Charlotteville', 'Merrow', 'Onslow Village']
      },
      {
        town_city: 'Reigate',
        county: 'Surrey',
        postcode_districts: %w[RH1 RH2],
        sale_range: 375_000..1_050_000,
        rent_range: 1_350..3_300,
        nearby: ['Priory Park', 'commuter rail services', 'independent cafes'],
        neighbourhoods: ['South Park', 'Reigate Hill', 'Woodhatch']
      },
      {
        town_city: 'Westerham',
        county: 'Kent',
        postcode_districts: %w[TN16],
        sale_range: 350_000..950_000,
        rent_range: 1_250..2_950,
        nearby: ['the village green', 'country walks', 'local primary schools'],
        neighbourhoods: ['Brasted', 'Valence', 'Crockham Hill']
      }
    ].freeze

    STREET_NAMES = %w[
      Albion
      Beech
      Calverley
      Cedar
      Church
      Grosvenor
      Heath
      Highfield
      Kings
      Lime
      Marlborough
      Meadow
      Mount
      Oak
      Orchard
      Park
      Priory
      Queens
      Rectory
      Richmond
      Station
      South
      Willow
    ].freeze

    STREET_SUFFIXES = %w[
      Close
      Court
      Crescent
      Drive
      Gardens
      Grove
      Lane
      Mews
      Place
      Road
      Street
      Terrace
    ].freeze

    POSTCODE_SUFFIX_LETTERS = %w[
      A B D E F G H J L N P R S T U W X Y Z
    ].freeze

    PROPERTY_TYPES = {
      sale: [
        'detached house',
        'semi-detached house',
        'Victorian terrace',
        'end-of-terrace house',
        'townhouse',
        'period conversion flat',
        'purpose-built flat'
      ],
      rent: [
        'garden flat',
        'purpose-built flat',
        'maisonette',
        'duplex apartment',
        'modern apartment',
        'terraced house'
      ]
    }.freeze

    SHARED_FEATURE_BANK = [
      'a bright bay-fronted sitting room',
      'a contemporary shaker-style kitchen',
      'useful built-in storage',
      'an en-suite principal bedroom',
      'a study nook for home working'
    ].freeze

    HOUSE_FEATURE_BANK = [
      'a landscaped rear garden',
      'allocated parking',
      'a separate utility cupboard',
      'a generous kitchen diner',
      'a loft room for flexible use'
    ].freeze

    UNIT_FEATURE_BANK = [
      'a private balcony',
      'secure entry',
      'lift access',
      'well-proportioned open-plan living space',
      'an efficient utility cupboard'
    ].freeze

    GARDEN_FLAT_FEATURE_BANK = [
      'a private patio garden'
    ].freeze

    BEDROOM_WEIGHTS = {
      'For Sale' => [[1, 1], [2, 3], [3, 4], [4, 3], [5, 2]],
      'For Rent' => [[1, 3], [2, 4], [3, 3], [4, 1]]
    }.freeze

    PROPERTY_TYPE_BEDROOM_WEIGHTS = {
      'detached house' => [[3, 2], [4, 4], [5, 3]],
      'semi-detached house' => [[2, 2], [3, 4], [4, 3], [5, 1]],
      'Victorian terrace' => [[2, 3], [3, 4], [4, 2]],
      'end-of-terrace house' => [[2, 3], [3, 4], [4, 2]],
      'townhouse' => [[2, 2], [3, 4], [4, 2]],
      'period conversion flat' => [[1, 2], [2, 4], [3, 2]],
      'purpose-built flat' => [[1, 3], [2, 4], [3, 2]],
      'garden flat' => [[1, 2], [2, 4], [3, 2]],
      'maisonette' => [[1, 1], [2, 4], [3, 3]],
      'duplex apartment' => [[1, 1], [2, 4], [3, 3]],
      'modern apartment' => [[1, 3], [2, 4], [3, 1]],
      'terraced house' => [[2, 3], [3, 4], [4, 1]]
    }.freeze

    PROPERTY_TYPE_PRICE_FACTORS = {
      'detached house' => 1.18,
      'semi-detached house' => 1.02,
      'Victorian terrace' => 0.94,
      'end-of-terrace house' => 0.92,
      'townhouse' => 0.97,
      'period conversion flat' => 0.84,
      'purpose-built flat' => 0.78,
      'garden flat' => 0.86,
      'maisonette' => 0.83,
      'duplex apartment' => 0.88,
      'modern apartment' => 0.8,
      'terraced house' => 0.91
    }.freeze

    def initialize(random: Random.new)
      @random = random
    end

    def build_batch(count:, sale_status: nil, starting_index: 0, featured: nil)
      Array.new(count) { |index| build(index: starting_index + index, sale_status:, featured:) }
    end

    def build(index:, sale_status: nil, featured: nil)
      sale_status ||= weighted_pick([['For Sale', 3], ['For Rent', 2]])
      area = AREA_CATALOG.sample(random: random)
      property_type = property_type_for(sale_status)
      bedrooms = bedrooms_for(property_type, sale_status)
      bathrooms = [1, [bedrooms - 1, 1].max, bedrooms].min
      features = feature_bank_for(property_type).sample(3, random: random)

      address_line_1, address_line_2 = address_for(property_type, area:, index:)
      base_price = base_price_for(area: area, sale_status: sale_status, bedrooms: bedrooms, property_type: property_type)

      {
        address_line_1: address_line_1,
        address_line_2: address_line_2,
        town_city: area.fetch(:town_city),
        county: area.fetch(:county),
        postcode: postcode_for(area),
        country: 'United Kingdom',
        property_type: property_type.titleize,
        listing_tagline: tagline_for(property_type:, area:, features:),
        property_description: description_for(
          property_type: property_type,
          area: area,
          sale_status: sale_status,
          bedrooms: bedrooms,
          features: features
        ),
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        sale_status: sale_status,
        asking_price: base_price,
        featured: featured.nil? ? index % 6 == 0 : featured,
        prompt_context: {
          property_type: property_type,
          nearby: area.fetch(:nearby),
          features: features
        }
      }
    end

    private

    attr_reader :random

    def weighted_pick(weighted_values)
      total_weight = weighted_values.sum(&:last)
      point = random.rand(total_weight)

      weighted_values.each do |value, weight|
        return value if point < weight

        point -= weight
      end

      weighted_values.last.first
    end

    def property_type_for(sale_status)
      key = sale_status == 'For Sale' ? :sale : :rent
      PROPERTY_TYPES.fetch(key).sample(random: random)
    end

    def bedrooms_for(property_type, sale_status)
      weights = PROPERTY_TYPE_BEDROOM_WEIGHTS.fetch(property_type, BEDROOM_WEIGHTS.fetch(sale_status))
      weighted_pick(weights)
    end

    def feature_bank_for(property_type)
      bank = SHARED_FEATURE_BANK.dup
      bank.concat(unit_style_property?(property_type) ? UNIT_FEATURE_BANK : HOUSE_FEATURE_BANK)
      bank.concat(GARDEN_FLAT_FEATURE_BANK) if property_type.include?('garden flat')
      bank.uniq
    end

    def address_for(property_type, area:, index:)
      number = (index + 3) * 2
      street = "#{STREET_NAMES.sample(random: random)} #{STREET_SUFFIXES.sample(random: random)}"
      neighbourhood = random.rand < 0.65 ? area.fetch(:neighbourhoods).sample(random: random) : ''

      if unit_style_property?(property_type)
        unit_label = unit_label_for(property_type)

        ["#{unit_label} #{1 + random.rand(18)}, #{number} #{street}", neighbourhood]
      else
        ["#{number} #{street}", neighbourhood]
      end
    end

    def unit_style_property?(property_type)
      property_type.match?(/apartment|flat|maisonette/)
    end

    def postcode_for(area)
      district = area.fetch(:postcode_districts).sample(random: random)
      sector = 1 + random.rand(9)
      suffix = "#{POSTCODE_SUFFIX_LETTERS.sample(random: random)}#{POSTCODE_SUFFIX_LETTERS.sample(random: random)}"
      "#{district} #{sector}#{suffix}"
    end

    def unit_label_for(property_type)
      return 'Maisonette' if property_type.include?('maisonette')
      return 'Flat' if property_type.include?('flat')

      'Apartment'
    end

    def base_price_for(area:, sale_status:, bedrooms:, property_type:)
      range = sale_status == 'For Sale' ? area.fetch(:sale_range) : area.fetch(:rent_range)
      ratio =
        case bedrooms
        when 1 then 0.18
        when 2 then 0.36
        when 3 then 0.56
        when 4 then 0.76
        else 0.92
        end

      factor = PROPERTY_TYPE_PRICE_FACTORS.fetch(property_type, 1.0)
      base = range.begin + ((range.end - range.begin) * ratio * factor).round
      variance = sale_status == 'For Sale' ? 35_000 : 175
      rounded_price(base + random.rand(-variance..variance), sale_status)
    end

    def rounded_price(value, sale_status)
      if sale_status == 'For Sale'
        [[value, 175_000].max, 2_500_000].min.round(-3)
      else
        rounded = ([[value, 750].max, 6_500].min / 25.0).round * 25
        rounded.to_i
      end
    end

    def description_for(property_type:, area:, sale_status:, bedrooms:, features:)
      bedroom_label = bedrooms == 1 ? 'one bedroom' : "#{bedrooms} bedrooms"
      nearby = area.fetch(:nearby)

      if sale_status == 'For Sale'
        "#{article_for(property_type)} #{property_type} in #{area.fetch(:town_city)} offering #{bedroom_label}, #{features[0]}, and #{features[1]}. " \
          "Well placed for #{nearby.first} and #{nearby.last}, the home should appeal to buyers who want comfort, practicality, and an easy day-to-day setting. " \
          "#{features[2].capitalize} helps round out a believable long-term family or downsizer move."
      else
        "#{article_for(property_type)} #{property_type} in #{area.fetch(:town_city)} with #{bedroom_label}, #{features[0]}, and #{features[1]}. " \
          "It is handy for #{nearby.first} and #{nearby.last}, making it a strong rental option for tenants who want a straightforward commute and local convenience. " \
          "#{features[2].capitalize} gives the layout some extra everyday appeal."
      end
    end

    def tagline_for(property_type:, area:, features:)
      "#{property_type.capitalize} near #{area.fetch(:nearby).first} with #{features.first.sub(/\Aa /, '')}"
    end

    def article_for(property_type)
      property_type.match?(/\A[aeiou]/i) ? 'An' : 'A'
    end
  end
end
