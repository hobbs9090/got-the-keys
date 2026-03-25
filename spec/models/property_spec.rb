require 'rails_helper'

describe "A property" do
  let(:user) { User.create!(user_attributes) }

  def build_property(overrides = {})
    Property.new(property_attributes({ user_id: user.id }.merge(overrides)))
  end

  #it "belongs to a user" do
  #  user = User.create(user_attributes)
  #
  #  property = user.properties.new(for_sale_attributes)
  #
  #  expect(property.user).to eq(property)
  #end

  it "with example attributes is valid" do
    property = build_property

    expect(property.valid?).to be true
  end

  it "requires a Address line 1" do
    property = build_property(address_line_1: "")

    expect(property.valid?).to be false
    expect(property.errors[:address_line_1].any?).to be true
    expect(property.errors[:address_line_1].first).to eq("can't be blank")
  end

  it "requires a Town or City" do
    property = build_property(town_city: "")

    expect(property.valid?).to be false
    expect(property.errors[:town_city].any?).to be true
    expect(property.errors[:town_city].first).to eq("can't be blank")
  end

  it "requires a County" do
    property = build_property(county: "")

    expect(property.valid?).to be false
    expect(property.errors[:county].any?).to be true
    expect(property.errors[:county].first).to eq("can't be blank")
  end

  it "requires a Postcode" do
    property = build_property(postcode: "")

    expect(property.valid?).to be false
    expect(property.errors[:postcode].any?).to be true
    expect(property.errors[:postcode].first).to eq("can't be blank")
  end

  it "requires a Country" do
    property = build_property(country: "")

    expect(property.valid?).to be false
    expect(property.errors[:country].any?).to be true
    expect(property.errors[:country].first).to eq("can't be blank")
  end

  it "requires a Property Description min 25 characters" do
    property = build_property(property_description: "X" * 24)

    expect(property.valid?).to be false
    expect(property.errors[:property_description].any?).to be true
    expect(property.errors[:property_description].first).to eq("is too short (minimum is 25 characters)")
  end

  it "requires number of bedrooms" do
    property = build_property(bedrooms: '')

    expect(property.valid?).to be false
    expect(property.errors[:bedrooms].any?).to be true
    expect(property.errors[:bedrooms].first).to eq("can't be blank")
  end

  it "rejects invalid number of bedrooms" do
    bedrooms = [-1, -5]
    bedrooms.each do |bedrooms|
      property = build_property(bedrooms: bedrooms)

      expect(property.valid?).to be false
      expect(property.errors[:bedrooms].any?).to be true
      expect(property.errors[:bedrooms].first).to eq("must be greater than or equal to 0")
    end
  end

  it "requires bathrooms" do
    property = build_property(bathrooms: nil)

    expect(property.valid?).to be false
    expect(property.errors[:bathrooms]).to include("can't be blank")
  end

  it "accepts Sale Status values of 'For Sale' or 'For Rent'" do
    sale_status = ['For Sale', 'For Rent']
    sale_status.each do |sale_status|
      property = build_property(sale_status: sale_status)

      expect(property.valid?).to be true
      expect(property.errors[:sale_status].any?).to be false
    end
  end

  it "rejects invalid Sale Status values" do
    sale_status = ['For Demolition', 'For Redevelopment']
    sale_status.each do |sale_status|
      property = build_property(sale_status: sale_status)

      expect(property.valid?).to be false
      expect(property.errors[:sale_status].any?).to be true
      expect(property.errors[:sale_status].first).to eq("is not included in the list")
    end
  end

  it "accepts svg image filenames for lightweight placeholder artwork" do
    property = build_property(image_file_name: "property_placeholder_listing.svg")

    expect(property.valid?).to be true
    expect(property.errors[:image_file_name]).to be_empty
  end

  it "rejects unsupported image filename extensions" do
    property = build_property(image_file_name: "property_placeholder_listing.webp")

    expect(property.valid?).to be false
    expect(property.errors[:image_file_name]).to include("must reference a GIF, JPG, PNG, or SVG image")
  end
end
