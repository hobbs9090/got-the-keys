require 'rails_helper'

property1 = Property.create!(address_line_1: "Little Orchard",
                             address_line_2: "Buckham Thorns Road",
                             town_city: "Westerham",
                             county: "Kent",
                             postcode: "TN16 1ET",
                             country: "United Kingdom",
                             property_description: "A spacious detached family house recently extended for the current owners.",
                             bedrooms: 4,
                             sale_status: "For Sale",
                             asking_price: 600000.00,
                             user_id: 1)

property2 = Property.create!(address_line_1: "14 Bazley Road",
                             town_city: "Northenden",
                             county: "Manchester",
                             postcode: "M22 4FL",
                             country: "United Kingdom",
                             property_description: "A beautifully presented semi close to all local amenities and transport links.",
                             bedrooms: 2,
                             sale_status: "For Rent",
                             asking_price: 180000.00,
                             user_id: 1)

describe "Viewing the list of properties for sale" do

  it "shows the properties for sale" do
    visit for_sale_index_url

    expect(page).to have_text("Little Orchard")
  end
end

describe "Viewing the list of properties for rent" do

  it "shows the properties for rent" do
    visit for_rent_index_url

    expect(page).to have_text("14 Bazley Road")
  end
end
