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
      property_type: "Detached house",
      listing_tagline: "Detached house near Sevenoaks station with generous rear garden",
      property_description: "A well-presented detached house with a bright kitchen diner, generous rear garden, off-street parking, and a study for home working.",
      bedrooms: 4,
      bathrooms: 3,
      sale_status: "For Sale",
      asking_price: 1_050_000
    )
  end

  it "builds a premium-looking estate-agent image prompt from the property details" do
    prompt = described_class.new.prompt_for(property)

    expect(prompt).to include("4-bedroom, 3-bathroom detached house in Sevenoaks, Kent")
    expect(prompt).to include("leafy Sevenoaks residential lane")
    expect(prompt).to include("bright kitchen diner")
    expect(prompt).to include("off-street parking")
    expect(prompt).to include("Do not include any readable street signs, house numbers")
    expect(prompt).to include(property.headline)
  end
end
