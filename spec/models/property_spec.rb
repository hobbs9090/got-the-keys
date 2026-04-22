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

  it "uses an even page size for catalogue listings" do
    expect(Property.default_per_page).to eq(12)
  end

  it "supports the richer listing lifecycle states" do
    Property::LISTING_STATES.each do |listing_state|
      property = build_property(listing_state: listing_state)

      expect(property.valid?).to be(true)
    end
  end

  it "calculates listing completeness from structured facts and assets" do
    property = FactoryBot.create(:property, user:)
    FactoryBot.create(:photo, property:, primary: true)
    FactoryBot.create(:floor_plan, property:)

    expect(property.listing_completeness_score).to eq(5)
    expect(property.listing_completeness_percentage).to eq(100)
    expect(property).to be_ready_for_review
  end

  it "falls short of review readiness when key facts and assets are missing" do
    property = FactoryBot.create(
      :property,
      user:,
      listing_tagline: nil,
      image_file_name: nil,
      tenure: nil,
      council_tax_band: nil,
      floor_area_sq_ft: nil
    )

    expect(property.listing_completeness_score).to be < property.listing_completeness_checks.size
    expect(property).not_to be_ready_for_review
  end

  it "enforces a required seller at the database level" do
    property = FactoryBot.create(:property, user:)

    expect { property.update_column(:user_id, nil) }.to raise_error(ActiveRecord::NotNullViolation)
  end

  it "requires a Address line 1" do
    property = build_property(address_line_1: "")

    expect(property.valid?).to be false
    expect(property.errors[:address_line_1].any?).to be true
    expect(property.errors[:address_line_1].first).to eq("can't be blank")
  end

  it "rejects a duplicate property at the same address" do
    FactoryBot.create(
      :property,
      user:,
      address_line_1: "24 Cedar Road",
      address_line_2: nil,
      postcode: "TN13 1AA",
      country: "United Kingdom"
    )

    duplicate = build_property(
      address_line_1: " 24 cedar road ",
      address_line_2: "",
      postcode: "TN13   1AA",
      country: " united kingdom "
    )

    expect(duplicate.valid?).to be false
    expect(duplicate.errors[:address_line_1]).to include("has already been listed for this address")
  end

  it "allows matching first address lines when the second address line is different" do
    FactoryBot.create(
      :property,
      user:,
      address_line_1: "Orchard House",
      address_line_2: "Flat 1",
      postcode: "TN16 1ET"
    )

    property = build_property(
      address_line_1: "Orchard House",
      address_line_2: "Flat 2",
      postcode: "TN16 1ET"
    )

    expect(property.valid?).to be true
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
    property = build_property(image_file_name: "properties/property_placeholder_listing.svg")

    expect(property.valid?).to be true
    expect(property.errors[:image_file_name]).to be_empty
  end

  it "rejects image filenames with spaces" do
    property = build_property(image_file_name: "my image.jpg")

    expect(property.valid?).to be false
    expect(property.errors[:image_file_name]).to be_present
  end

  it "strips commas from asking price before validation" do
    property = build_property(asking_price: "650,000")

    expect(property.valid?).to be true
    expect(property.asking_price).to eq(650_000)
  end

  it "accepts jpeg image filenames" do
    property = build_property(image_file_name: "/uploads/property_images/example.jpeg")

    expect(property.valid?).to be true
    expect(property.errors[:image_file_name]).to be_empty
  end

  it "rejects refurbishment years earlier than the build year" do
    property = build_property(year_built: 2005, refurbished_year: 2001)

    expect(property.valid?).to be false
    expect(property.errors[:refurbished_year]).to include("must be greater than or equal to the year built")
  end

  it "clears furnishing details for sale listings" do
    property = build_property(sale_status: Property::SALE_STATUSES[:for_sale], furnishing: "Part furnished")

    property.valid?

    expect(property.furnishing).to be_nil
  end

  it "clears rent-only fields for freehold sale listings" do
    property = build_property(
      sale_status: Property::SALE_STATUSES[:for_sale],
      tenure: "Freehold",
      deposit_amount: 2_500,
      lease_length_years: 999,
      pets_allowed: true
    )

    property.valid?

    expect(property.deposit_amount).to be_nil
    expect(property.lease_length_years).to be_nil
    expect(property.pets_allowed).to be(false)
  end

  it "clears pets allowed for freehold rental listings" do
    property = build_property(
      sale_status: Property::SALE_STATUSES[:for_rent],
      tenure: "Freehold",
      pets_allowed: true
    )

    property.valid?

    expect(property.pets_allowed).to be(false)
  end

  it "clears lease length for freehold rental listings" do
    property = build_property(
      sale_status: Property::SALE_STATUSES[:for_rent],
      tenure: "Freehold",
      lease_length_years: 999
    )

    property.valid?

    expect(property.lease_length_years).to be_nil
  end

  it "keeps lease length for non-freehold sale listings" do
    property = build_property(
      sale_status: Property::SALE_STATUSES[:for_sale],
      tenure: "Leasehold",
      lease_length_years: 125
    )

    property.valid?

    expect(property.lease_length_years).to eq(125)
  end

  it "accepts webp image filenames" do
    property = build_property(image_file_name: "properties/property_placeholder_listing.webp")

    expect(property.valid?).to be true
    expect(property.errors[:image_file_name]).to be_empty
  end

  it "does not resolve upload paths outside the upload root" do
    property = FactoryBot.create(:property, user:)
    property.update_column(:image_file_name, "/uploads/property_images/../../../etc/passwd.jpg")

    expect(property.send(:uploaded_image_absolute_path, property.image_file_name)).to be_nil
  end

  it "uses the primary photo as the hero image when present" do
    property = FactoryBot.create(:property, user:, image_file_name: "fallback.svg")
    FactoryBot.create(:photo, property:, image_filename: "gallery-1.jpg", primary: false, position: 2)
    FactoryBot.create(:photo, property:, image_filename: "gallery-cover.jpg", primary: true, position: 1)

    expect(property.hero_image_name).to eq("gallery-cover.jpg")
  end

  it "favours listings with imagery in the recommended order" do
    image_backed = FactoryBot.create(:property, user:, address_line_1: "Image Backed Place", featured: false)
    text_only = FactoryBot.create(:property, user:, address_line_1: "Text Only Place", featured: false)
    FactoryBot.create(:photo, property: image_backed, image_filename: "image-backed-place.jpg", primary: true, position: 1)

    image_backed.update_columns(updated_at: 2.days.ago)
    text_only.update_columns(updated_at: 1.day.ago)

    expect(Property.recommended_order.limit(2).pluck(:address_line_1)).to eq([
      "Image Backed Place",
      "Text Only Place"
    ])
  end
end
