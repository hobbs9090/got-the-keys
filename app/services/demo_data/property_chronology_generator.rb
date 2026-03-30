# frozen_string_literal: true

module DemoData
  class PropertyChronologyGenerator
    YEAR_PROFILES = [
      {
        pattern: /victorian terrace|cottage/i,
        build_range: 1850..1905,
        refurbish_start: 2008,
        refurbish_probability: 0.9,
        min_refurbishment_gap: 20
      },
      {
        pattern: /loft apartment/i,
        build_range: 1890..1975,
        refurbish_start: 2014,
        refurbish_probability: 0.95,
        min_refurbishment_gap: 20
      },
      {
        pattern: /period conversion flat|garden apartment|garden flat/i,
        build_range: 1870..1915,
        refurbish_start: 2010,
        refurbish_probability: 0.9,
        min_refurbishment_gap: 18
      },
      {
        pattern: /semi-detached house/i,
        build_range: 1925..2016,
        refurbish_start: 2008,
        refurbish_probability: 0.7,
        min_refurbishment_gap: 10
      },
      {
        pattern: /detached house/i,
        build_range: 1955..2018,
        refurbish_start: 2012,
        refurbish_probability: 0.65,
        min_refurbishment_gap: 8
      },
      {
        pattern: /end-of-terrace house|terraced house/i,
        build_range: 1890..2012,
        refurbish_start: 2008,
        refurbish_probability: 0.75,
        min_refurbishment_gap: 12
      },
      {
        pattern: /townhouse/i,
        build_range: 1990..2024,
        refurbish_start: 2018,
        refurbish_probability: 0.45,
        min_refurbishment_gap: 6
      },
      {
        pattern: /maisonette/i,
        build_range: 1930..2015,
        refurbish_start: 2010,
        refurbish_probability: 0.65,
        min_refurbishment_gap: 8
      },
      {
        pattern: /purpose-built flat|modern apartment|modern flat|apartment|rental flat|balcony flat|duplex apartment/i,
        build_range: 1995..2024,
        refurbish_start: 2019,
        refurbish_probability: 0.45,
        min_refurbishment_gap: 4
      }
    ].freeze

    DEFAULT_PROFILE = {
      build_range: 1955..2020,
      refurbish_start: 2012,
      refurbish_probability: 0.55,
      min_refurbishment_gap: 8
    }.freeze

    def initialize(random: Random.new, current_year: Date.current.year)
      @random = random
      @current_year = current_year
    end

    def generate(property_type:, sale_status:, year_built: nil, refurbished_year: nil)
      profile = profile_for(property_type)
      sampled_year_built = year_built.presence&.to_i || sample_year(profile.fetch(:build_range))
      sampled_refurbished_year =
        refurbished_year.presence&.to_i || sample_refurbished_year(
          profile,
          sampled_year_built,
          sale_status: sale_status
        )

      {
        year_built: sampled_year_built,
        refurbished_year: sampled_refurbished_year
      }
    end

    private

    attr_reader :random, :current_year

    def profile_for(property_type)
      normalized_type = property_type.to_s
      YEAR_PROFILES.find { |profile| normalized_type.match?(profile.fetch(:pattern)) } || DEFAULT_PROFILE
    end

    def sample_year(range)
      min_year = range.begin
      max_year = [range.end, current_year].min

      random.rand(min_year..max_year)
    end

    def sample_refurbished_year(profile, year_built, sale_status:)
      return if year_built.blank?
      return if year_built >= current_year - 4
      return if random.rand >= refurbishment_probability_for(profile, sale_status:)

      min_year = [profile.fetch(:refurbish_start), year_built + profile.fetch(:min_refurbishment_gap)].max
      return if min_year > current_year

      random.rand(min_year..current_year)
    end

    def refurbishment_probability_for(profile, sale_status:)
      probability = profile.fetch(:refurbish_probability)
      probability += 0.1 if sale_status == Property::SALE_STATUSES[:for_rent]

      [probability, 0.95].min
    end
  end
end
