# frozen_string_literal: true

module DemoData
  class PropertyImagePromptBuilder
    EXTERIOR_VIEW_DIRECTIONS = {
      left: "Use a front three-quarter exterior angle from the left-hand side.",
      right: "Use a front three-quarter exterior angle from the right-hand side."
    }.freeze

    INTERIOR_VIEW_NOTES = [
      "Prefer an interior hero image showing the most impressive living area, with believable daylight, depth, and polished estate-agent composition.",
      "Prefer an interior hero image centred on a bright main reception room or open-plan living space, with elegant styling and natural light.",
      "Prefer an interior hero image that highlights a standout kitchen-diner or principal living area, composed like a premium estate-agent photograph."
    ].freeze

    INTERIOR_WEATHER_NOTES = [
      "Let the window light suggest a calm clear day without making the room feel harsh or overly sunny.",
      "Let the light read as softly overcast outside, giving the room an even, premium brightness.",
      "Let the scene feel just after light rain, with gentle daylight and a fresh, polished atmosphere beyond the windows."
    ].freeze

    EXTERIOR_LIGHTING_NOTES = [
      "Use bright late-morning daylight with soft shadows and a calm blue-sky feel.",
      "Use clean early-afternoon daylight with crisp contrast and fresh seasonal greenery.",
      "Use soft, even daylight with premium estate-agent clarity and realistic skies."
    ].freeze

    EXTERIOR_WEATHER_NOTES = [
      "Set it on a calm clear day with attractive blue sky and believable seasonal brightness.",
      "Set it under refined soft overcast conditions with bright cloud cover and flattering, even light.",
      "Set it shortly after a light shower, with fresh greenery, subtly damp paving, and clearing skies."
    ].freeze

    AREA_STYLE_NOTES = {
      "Sevenoaks" => "Show an affluent leafy Sevenoaks residential lane with mature trees, polished front gardens, and premium Kent commuter-belt character.",
      "Westerham" => "Show a picturesque Westerham village-edge setting with greenery, charming Kent character, and an attractive upmarket residential feel."
    }.freeze

    PROPERTY_TYPE_STYLE_NOTES = {
      "House" => "Show a handsome British house with confident kerb appeal, balanced frontage, and a neat driveway or approach where appropriate.",
      "Flat" => "Show a polished flat or apartment building entrance or facade with contemporary residential appeal and believable UK context."
    }.freeze

    FEATURE_VISUAL_CUES = [
      [/rear garden|garden/i, "Make the landscaping feel lush and well maintained, with a strong sense of outdoor appeal."],
      [/parking|driveway|off-street/i, "Include a neat driveway or convenient parking arrangement without letting vehicles dominate the shot."],
      [/kitchen diner/i, "Hint at generous entertaining space with wide windows and an inviting lived-in glow."],
      [/study|home working/i, "Position the home as ideal for modern home working and comfortable day-to-day living."],
      [/storage|utility/i, "Give the home a practical, well-organised, move-in-ready feel."],
      [/principal bedroom|fitted wardrobes/i, "Suggest a well-finished upper floor and calm, premium bedroom accommodation."]
    ].freeze

    SALE_CONTEXT_NOTES = {
      "For Sale" => "Frame it for buyers seeking an aspirational but credible family home with strong long-term appeal.",
      "For Rent" => "Frame it for discerning tenants seeking a polished, desirable rental home that feels ready to move straight into."
    }.freeze

    def prompt_for(property)
      visual_plan = visual_plan_for(property)

      [
        "Create a striking but believable estate-agent hero photograph for a UK property listing.",
        property_summary(property),
        area_note_for(property),
        property_type_note_for(property),
        chronology_note_for(property),
        sale_context_for(property),
        feature_cues_for(property),
        visual_plan.fetch(:composition_note),
        visual_plan.fetch(:lighting_note),
        visual_plan.fetch(:weather_note),
        "Make the property look highly attractive, premium, and move-in ready, but still realistic and not fantasy CGI.",
        "Keep the proportions true to a real UK home of this exact type and size; do not turn it into a mansion or redesign the architecture.",
        "No people, no bin bags, no construction clutter, and no cars blocking the facade.",
        "Do not include any readable street signs, house numbers, logos, branding, watermarks, or text overlays.",
        "Listing context: #{listing_context_for(property)}"
      ].compact.join(" ")
    end

    private

    def visual_plan_for(property)
      seed = property.id.to_i.nonzero? || property.address_line_1.to_s.hash

      if interior_focused_property?(property)
        {
          composition_note: INTERIOR_VIEW_NOTES[seed % INTERIOR_VIEW_NOTES.length],
          lighting_note: "Keep it bright, airy, and realistic, with refined estate-agent styling and no exaggerated CGI gloss.",
          weather_note: INTERIOR_WEATHER_NOTES[seed % INTERIOR_WEATHER_NOTES.length]
        }
      else
        direction = seed.even? ? :left : :right

        {
          composition_note: [
            "Use professional luxury real-estate photography with wide framing, crisp detail, clean windows, tidy masonry, and strong kerb appeal.",
            EXTERIOR_VIEW_DIRECTIONS.fetch(direction)
          ].join(" "),
          lighting_note: EXTERIOR_LIGHTING_NOTES[seed % EXTERIOR_LIGHTING_NOTES.length],
          weather_note: EXTERIOR_WEATHER_NOTES[seed % EXTERIOR_WEATHER_NOTES.length]
        }
      end
    end

    def interior_focused_property?(property)
      type = property.property_type.to_s.downcase
      interior_type = type == "flat"
      searchable_text = [property.listing_tagline, property.property_description].compact.join(" ")
      has_strong_exterior_cue = searchable_text.match?(/garden|terrace|balcony|driveway|parking|facade|frontage/i)

      return true if interior_type && !has_strong_exterior_cue

      interior_type && ((property.id.to_i.nonzero? || searchable_text.hash).abs % 10) < 7
    end

    def property_summary(property)
      "The home is a #{property.bedrooms}-bedroom, #{property.bathrooms}-bathroom #{property.property_type.to_s.downcase} in #{property.town_city}, #{property.county}, United Kingdom."
    end

    def area_note_for(property)
      AREA_STYLE_NOTES.fetch(property.town_city, "Show an attractive Kent residential setting with greenery, tidy streets, and polished surroundings.")
    end

    def property_type_note_for(property)
      PROPERTY_TYPE_STYLE_NOTES.fetch(property.property_type, "Show an attractive, well-kept British home with strong kerb appeal.")
    end

    def sale_context_for(property)
      SALE_CONTEXT_NOTES[property.sale_status]
    end

    def chronology_note_for(property)
      return if property.year_built.blank? && property.refurbished_year.blank?

      notes = []

      if property.year_built.present?
        notes << "The building dates from #{property.year_built} and should read as a believable #{architectural_era_for(property.year_built)} UK home, with rooflines, windows, and materials that suit that period."
      end

      if property.refurbished_year.present?
        notes << "Reflect tasteful updates completed in #{property.refurbished_year} while keeping the original character and scale coherent."
      end

      notes.join(" ")
    end

    def feature_cues_for(property)
      searchable_text = [property.listing_tagline, property.property_description].compact.join(" ")
      cues = FEATURE_VISUAL_CUES.filter_map { |pattern, cue| cue if searchable_text.match?(pattern) }.first(3)
      return nil if cues.empty?

      cues.join(" ")
    end

    def listing_context_for(property)
      pieces = [property.headline.presence, property.property_description.to_s.squish]
      pieces.compact.join(" ").truncate(420, separator: " ")
    end

    def architectural_era_for(year_built)
      case year_built.to_i
      when ..1836 then "Georgian-era"
      when 1837..1901 then "Victorian-era"
      when 1902..1918 then "Edwardian-era"
      when 1919..1939 then "interwar-era"
      when 1940..1969 then "mid-century"
      when 1970..1999 then "late-20th-century"
      else "early-21st-century"
      end
    end
  end
end
