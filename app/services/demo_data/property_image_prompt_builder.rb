# frozen_string_literal: true

module DemoData
  class PropertyImagePromptBuilder
    AREA_STYLE_NOTES = {
      "Sevenoaks" => "Show an affluent leafy Sevenoaks residential lane with mature trees, polished front gardens, and premium Kent commuter-belt character.",
      "Westerham" => "Show a picturesque Westerham village-edge setting with greenery, charming Kent character, and an attractive upmarket residential feel."
    }.freeze

    PROPERTY_TYPE_STYLE_NOTES = {
      "Detached house" => "Show a handsome detached family home with confident kerb appeal, balanced frontage, and a neat driveway or approach.",
      "Semi-detached house" => "Show an elegant semi-detached house with strong symmetry, tidy frontage, and a warm family-home feel.",
      "End-of-terrace house" => "Show a polished end-of-terrace home with side access, smart frontage, and generous natural light.",
      "Townhouse" => "Show a refined multi-storey townhouse with tall windows, crisp lines, and a premium residential feel.",
      "Terraced house" => "Show a well-kept terraced house with attractive brickwork, inviting frontage, and tasteful planting.",
      "Cottage" => "Show a charming Kent cottage with characterful detailing, painted joinery, and mature planting."
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
      [
        "Create a striking but believable estate-agent hero photograph for a UK property listing.",
        property_summary(property),
        area_note_for(property),
        property_type_note_for(property),
        sale_context_for(property),
        feature_cues_for(property),
        "Use professional luxury real-estate photography, a front three-quarter exterior angle, wide framing, crisp detail, clean windows, tidy masonry, and bright natural daylight with soft blue-sky weather.",
        "Make the property look highly attractive, premium, and move-in ready, but still realistic and not fantasy CGI.",
        "Keep the proportions true to a real UK home of this exact type and size; do not turn it into a mansion or redesign the architecture.",
        "No people, no bin bags, no construction clutter, and no cars blocking the facade.",
        "Do not include any readable street signs, house numbers, logos, branding, watermarks, or text overlays.",
        "Listing context: #{listing_context_for(property)}"
      ].compact.join(" ")
    end

    private

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
  end
end
