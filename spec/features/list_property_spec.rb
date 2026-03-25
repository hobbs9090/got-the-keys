require 'rails_helper'

describe "Viewing the property for sale" do

  it "shows the property details" do
    user = FactoryBot.create(:user)
    property = user.properties.create!(property_attributes)

    visit property_url(property)

    expect(page).to have_text("Little Orchard")
    expect(page).to have_text("For Sale")
  end
end

describe "Viewing the property for rent" do

  it "shows the property details" do
    user = FactoryBot.create(:user)
    property = user.properties.create!(property_attributes(sale_status: 'For Rent'))

    visit property_url(property)

    expect(page).to have_text("Little Orchard")
    expect(page).to have_text("For Rent")
  end
end

describe "Viewing an individual property" do

  it "shows Studio when number of bedrooms is zero" do
    user = FactoryBot.create(:user)
    property = user.properties.create!(property_attributes(bedrooms: 0))

    visit property_url(property)

    expect(page).to have_text("Studio Flat")
  end

  it "shows '1 bedroom' when number of bedrooms is 1" do
    user = FactoryBot.create(:user)
    property = user.properties.create!(property_attributes(bedrooms: 1))

    visit property_url(property)

    expect(page).to have_text("1 bedroom")
  end

  it "shows '2 bedrooms' when number of bedrooms is 2" do
    user = FactoryBot.create(:user)
    property = user.properties.create!(property_attributes(bedrooms: 2))

    visit property_url(property)

    expect(page).to have_text("2 bedrooms")
  end
end
