require 'rails_helper'

describe "Viewing the list of properties for sale" do

  it "shows the properties for sale" do
    user = FactoryBot.create(:user)
    user.properties.create!(property_attributes)

    visit for_sale_index_url

    expect(page).to have_text("Little Orchard")
  end
end

describe "Viewing the list of properties for rent" do

  it "shows the properties for rent" do
    user = FactoryBot.create(:user)
    user.properties.create!(
      property_attributes(
        address_line_1: "14 Bazley Road",
        address_line_2: "",
        town_city: "Northenden",
        county: "Manchester",
        postcode: "M22 4FL",
        property_description: "A beautifully presented semi close to all local amenities and transport links.",
        bedrooms: 2,
        sale_status: "For Rent",
        asking_price: 180000.00
      )
    )

    visit for_rent_index_url

    expect(page).to have_text("14 Bazley Road")
  end
end
