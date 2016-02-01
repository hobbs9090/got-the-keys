require 'rails_helper'

describe "A property" do

  #it "belongs to a user" do
  #  user = User.create(user_attributes)
  #
  #  property = user.properties.new(for_sale_attributes)
  #
  #  expect(property.user).to eq(property)
  #end

  it "with example attributes is valid" do
    property = Property.new(property_attributes)

    expect(property.valid?).to be_true
  end

  it "requires a Address line 1" do
    property = Property.new(property_attributes(address_line_1: ""))

    expect(property.valid?).to be_false
    expect(property.errors[:address_line_1].any?).to be_true
    expect(property.errors[:address_line_1].first).to eq("can't be blank")
  end

  it "requires a Town or City" do
    property = Property.new(property_attributes(town_city: ""))

    expect(property.valid?).to be_false
    expect(property.errors[:town_city].any?).to be_true
    expect(property.errors[:town_city].first).to eq("can't be blank")
  end

  it "requires a County" do
    property = Property.new(property_attributes(county: ""))

    expect(property.valid?).to be_false
    expect(property.errors[:county].any?).to be_true
    expect(property.errors[:county].first).to eq("can't be blank")
  end

  it "requires a Postcode" do
    property = Property.new(property_attributes(postcode: ""))

    expect(property.valid?).to be_false
    expect(property.errors[:postcode].any?).to be_true
    expect(property.errors[:postcode].first).to eq("can't be blank")
  end

  it "requires a Country" do
    property = Property.new(property_attributes(country: ""))

    expect(property.valid?).to be_false
    expect(property.errors[:country].any?).to be_true
    expect(property.errors[:country].first).to eq("can't be blank")
  end

  it "requires a Property Description min 25 characters" do
    property = Property.new(property_attributes(property_description: "X" * 24))

    expect(property.valid?).to be_false
    expect(property.errors[:property_description].any?).to be_true
    expect(property.errors[:property_description].first).to eq("is too short (minimum is 25 characters)")
  end

  it "requires number of bedrooms" do
    property = Property.new(property_attributes(bedrooms: ''))

    expect(property.valid?).to be_false
    expect(property.errors[:bedrooms].any?).to be_true
    expect(property.errors[:bedrooms].first).to eq("can't be blank")
  end

  it "rejects invalid number of bedrooms" do
    bedrooms = [-1, -5]
    bedrooms.each do |bedrooms|
      property = Property.new(property_attributes(bedrooms: bedrooms))

      expect(property.valid?).to be_false
      expect(property.errors[:bedrooms].any?).to be_true
      expect(property.errors[:bedrooms].first).to eq("must be greater than or equal to 0")
    end
  end

  it "accepts Sale Status values of 'For Sale' or 'For Rent'" do
    sale_status = ['For Sale', 'For Rent']
    sale_status.each do |sale_status|
      property = Property.new(property_attributes(sale_status: sale_status))

      expect(property.valid?).to be_true
      expect(property.errors[:sale_status].any?).to be_false
    end
  end

  it "rejects invalid Sale Status values" do
    sale_status = ['For Demolition', 'For Redevelopment']
    sale_status.each do |sale_status|
      property = Property.new(property_attributes(sale_status: sale_status))

      expect(property.valid?).to be_false
      expect(property.errors[:sale_status].any?).to be_true
      expect(property.errors[:sale_status].first).to eq("is not included in the list")
    end
  end
end
