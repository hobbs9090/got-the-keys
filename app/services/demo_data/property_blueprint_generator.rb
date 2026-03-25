module DemoData
  class PropertyBlueprintGenerator
    AREA_CATALOG = [
      {
        town_city: 'Sevenoaks',
        county: 'Kent',
        postcode_districts: %w[TN13 TN14 TN15],
        sale_range: 425_000..1_350_000,
        rent_range: 1_550..3_950,
        nearby: ['Sevenoaks station', 'the high street', 'Knole Park']
      },
      {
        town_city: 'Tunbridge Wells',
        county: 'Kent',
        postcode_districts: %w[TN1 TN2 TN4],
        sale_range: 315_000..975_000,
        rent_range: 1_250..3_200,
        nearby: ['the Pantiles', 'mainline rail links', 'good local schools']
      },
      {
        town_city: 'Canterbury',
        county: 'Kent',
        postcode_districts: %w[CT1 CT2 CT3],
        sale_range: 265_000..780_000,
        rent_range: 1_050..2_750,
        nearby: ['the city centre', 'Canterbury West', 'the university quarter']
      },
      {
        town_city: 'Bromley',
        county: 'Greater London',
        postcode_districts: %w[BR1 BR2 BR3],
        sale_range: 365_000..1_150_000,
        rent_range: 1_400..3_650,
        nearby: ['Bromley South', 'the Glades', 'local parkland']
      },
      {
        town_city: 'Croydon',
        county: 'Greater London',
        postcode_districts: %w[CR0 CR2 CR8],
        sale_range: 245_000..785_000,
        rent_range: 1_150..2_950,
        nearby: ['East Croydon', 'tram connections', 'restaurant and retail options']
      },
      {
        town_city: 'Guildford',
        county: 'Surrey',
        postcode_districts: %w[GU1 GU2 GU4],
        sale_range: 395_000..1_250_000,
        rent_range: 1_450..3_850,
        nearby: ['Guildford station', 'the town centre', 'the Surrey Hills']
      },
      {
        town_city: 'Reigate',
        county: 'Surrey',
        postcode_districts: %w[RH1 RH2],
        sale_range: 375_000..1_050_000,
        rent_range: 1_350..3_300,
        nearby: ['Priory Park', 'commuter rail services', 'independent cafes']
      },
      {
        town_city: 'Westerham',
        county: 'Kent',
        postcode_districts: %w[TN16],
        sale_range: 350_000..950_000,
        rent_range: 1_250..2_950,
        nearby: ['the village green', 'country walks', 'local primary schools']
      }
    ].freeze

    STREET_NAMES = %w[
      Cedar
      Orchard
      Meadow
      Oak
      Willow
      Station
      Mill
      Church
      Park
      Brook
      Heath
      Holly
      Foxglove
      Quarry
      Lime
      Priory
      Queens
      Kings
      Richmond
      Lansdowne
    ].freeze

    STREET_SUFFIXES = %w[
      Road
      Avenue
      Close
      Lane
      Drive
      Gardens
      Crescent
      Hill
      Street
      Court
    ].freeze

    PROPERTY_TYPES = {
      sale: ['detached family home', 'semi-detached house', 'Victorian terrace', 'modern townhouse', 'purpose-built apartment'],
      rent: ['garden apartment', 'modern flat', 'duplex apartment', 'terraced house', 'mezzanine flat']
    }.freeze

    FEATURE_BANK = [
      'a bright double reception room',
      'a contemporary shaker-style kitchen',
      'useful built-in storage',
      'a landscaped rear garden',
      'a private balcony',
      'allocated parking',
      'a separate utility area',
      'an en-suite principal bedroom',
      'flexible work-from-home space',
      'well-proportioned open-plan living space'
    ].freeze

    BEDROOM_WEIGHTS = {
      'For Sale' => [[1, 1], [2, 3], [3, 4], [4, 3], [5, 2]],
      'For Rent' => [[1, 3], [2, 4], [3, 3], [4, 1]]
    }.freeze

    def initialize(random: Random.new)
      @random = random
    end

    def build_batch(count:)
      Array.new(count) { |index| build(index: index) }
    end

    def build(index:)
      sale_status = weighted_pick([['For Sale', 3], ['For Rent', 2]])
      area = AREA_CATALOG.sample(random: random)
      bedrooms = weighted_pick(BEDROOM_WEIGHTS.fetch(sale_status))
      property_type = property_type_for(sale_status)
      features = FEATURE_BANK.sample(3, random: random)

      address_line_1, address_line_2 = address_for(property_type, index)
      base_price = base_price_for(area: area, sale_status: sale_status, bedrooms: bedrooms)

      {
        address_line_1: address_line_1,
        address_line_2: address_line_2,
        town_city: area.fetch(:town_city),
        county: area.fetch(:county),
        postcode: postcode_for(area),
        country: 'United Kingdom',
        property_description: description_for(
          property_type: property_type,
          area: area,
          sale_status: sale_status,
          bedrooms: bedrooms,
          features: features
        ),
        bedrooms: bedrooms,
        sale_status: sale_status,
        asking_price: base_price,
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

    def address_for(property_type, index)
      number = (index + 3) * 2
      street = "#{STREET_NAMES.sample(random: random)} #{STREET_SUFFIXES.sample(random: random)}"

      if property_type.include?('apartment') || property_type.include?('flat')
        ["Flat #{1 + random.rand(24)}, #{number} #{street}", '']
      else
        ["#{number} #{street}", '']
      end
    end

    def postcode_for(area)
      district = area.fetch(:postcode_districts).sample(random: random)
      sector = 1 + random.rand(9)
      suffix = "#{('A'..'Z').to_a.sample(random: random)}#{('A'..'Z').to_a.sample(random: random)}"
      "#{district} #{sector}#{suffix}"
    end

    def base_price_for(area:, sale_status:, bedrooms:)
      range = sale_status == 'For Sale' ? area.fetch(:sale_range) : area.fetch(:rent_range)
      ratio =
        case bedrooms
        when 1 then 0.18
        when 2 then 0.36
        when 3 then 0.56
        when 4 then 0.76
        else 0.92
        end

      base = range.begin + ((range.end - range.begin) * ratio).round
      variance = sale_status == 'For Sale' ? 35_000 : 175
      rounded_price(base + random.rand(-variance..variance), sale_status)
    end

    def rounded_price(value, sale_status)
      if sale_status == 'For Sale'
        [[value, 175_000].max, 2_500_000].min.round(-3)
      else
        [[value, 750].max, 6_500].min.round(-1)
      end
    end

    def description_for(property_type:, area:, sale_status:, bedrooms:, features:)
      audience = sale_status == 'For Sale' ? 'buyers' : 'tenants'
      bedroom_label = bedrooms == 1 ? 'one bedroom' : "#{bedrooms} bedrooms"

      "#{property_type.capitalize} in #{area.fetch(:town_city)} offering #{bedroom_label}, #{features[0]}, and #{features[1]}. " \
        "The home is well placed for #{area.fetch(:nearby).first} and #{area.fetch(:nearby).last}, with #{features[2]} adding day-to-day practicality. " \
        "A strong option for #{audience} looking for a well-connected address in #{area.fetch(:county)}."
    end
  end
end
