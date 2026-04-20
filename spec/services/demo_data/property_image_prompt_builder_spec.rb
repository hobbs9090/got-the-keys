require "rails_helper"

RSpec.describe DemoData::PropertyImagePromptBuilder do
  let(:property) do
    user = FactoryBot.create(:user)

    Property.create!(
      user: user,
      address_line_1: "18 Cedar Road",
      address_line_2: "Riverhead",
      town_city: "Sevenoaks",
      county: "Kent",
      postcode: "TN13 2AB",
      country: "United Kingdom",
      property_type: "House",
      listing_tagline: "Detached house near Sevenoaks station with generous rear garden",
      property_description: "A well-presented detached house with a bright kitchen diner, generous rear garden, off-street parking, and a study for home working.",
      bedrooms: 4,
      bathrooms: 3,
      sale_status: "For Sale",
      asking_price: 1_050_000,
      year_built: 1934,
      refurbished_year: 2021
    )
  end

  it "builds a premium-looking estate-agent image prompt from the property details" do
    prompt = described_class.new.prompt_for(property)

    expect(prompt).to include("4-bedroom, 3-bathroom house in Sevenoaks, Kent")
    expect(prompt).to include("leafy Sevenoaks residential lane")
    expect(prompt).to include("bright kitchen diner")
    expect(prompt).to include("off-street parking")
    expect(prompt).to include("dates from 1934")
    expect(prompt).to include("interwar-era")
    expect(prompt).to include("updates completed in 2021")
    expect(prompt).to include("Do not include any readable street signs, house numbers")
    expect(prompt).to include(property.headline)
    expect(prompt).to match(/front three-quarter exterior angle from the (left-hand|right-hand) side/)
    expect(prompt).to match(/calm clear day|soft overcast conditions|shortly after a light shower/)
  end

  it "prefers interior compositions for flat-like homes" do
    property.update!(
      property_type: "Flat",
      listing_tagline: "Garden flat with bright reception room",
      property_description: "A polished flat with a bright reception room, calm bedroom, and refined interior finishes."
    )

    prompt = described_class.new.prompt_for(property)

    expect(prompt).to include("Prefer an interior hero image")
    expect(prompt).to match(/window light suggest a calm clear day|light read as softly overcast|feel just after light rain/)
  end
end
