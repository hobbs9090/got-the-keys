require "rails_helper"

RSpec.describe DemoData::PropertyImageGenerator do
  let(:property) do
    user = FactoryBot.create(:user)

    Property.create!(
      user: user,
      address_line_1: "6 Parkside Mews",
      address_line_2: "",
      town_city: "Westerham",
      county: "Kent",
      postcode: "TN16 4FS",
      country: "United Kingdom",
      property_type: "House",
      listing_tagline: "Semi-detached house for buyers near the green with a bright kitchen diner",
      property_description: "A polished semi-detached house with a bright kitchen diner, a separate utility room, and good built-in storage.",
      bedrooms: 3,
      bathrooms: 2,
      sale_status: "For Sale",
      asking_price: 930_000,
      year_built: 1936,
      refurbished_year: 2021
    )
  end

  let(:fake_image) { Struct.new(:b64_json, :revised_prompt).new(Base64.strict_encode64("fake-jpeg-binary"), "revised prompt") }
  let(:fake_response) { Struct.new(:data).new([fake_image]) }
  let(:images_resource) { instance_double("ImagesResource", generate: fake_response) }
  let(:fake_client) { instance_double(OpenAI::Client, images: images_resource) }
  let(:generated_filename) { "properties/property_6_parkside_mews_hero.jpg" }

  around do |example|
    Dir.mktmpdir do |dir|
      @output_dir = Pathname(dir)
      example.run
    end
  end

  it "defaults to writing generated files into the Rails asset image directory" do
    generator = described_class.new(client: fake_client)

    expect(generator.send(:output_dir)).to eq(described_class::DEFAULT_OUTPUT_DIR)
  end

  it "writes a generated image file and attaches it as the primary property photo" do
    result = described_class.new(client: fake_client, output_dir: @output_dir).generate_for_property(property)

    expect(result[:status]).to eq(:generated)
    expect(result[:asset_pipeline_managed]).to be(false)
    expect(property.reload.image_file_name).to be_blank
    expect(property.photos.count).to eq(1)
    expect(property.primary_photo).to have_attributes(
      image_filename: generated_filename,
      primary: true,
      caption: property.headline
    )
    expect(@output_dir.join(generated_filename).binread).to eq("fake-jpeg-binary")
  end

  it "supports dry-run prompt previews without updating the property" do
    result = described_class.new(client: fake_client, output_dir: @output_dir, dry_run: true).generate_for_property(property)

    expect(result[:status]).to eq(:preview)
    expect(result[:prompt]).to include(property.town_city)
    expect(result).to include(
      year_built: 1936,
      refurbished_year: 2021
    )
    expect(property.reload.image_file_name).to be_blank
    expect(property.photos).to be_empty
  end

  it "processes scopes in configurable batches" do
    other_properties = FactoryBot.create_list(:property, 2)

    report = described_class.new(client: fake_client, output_dir: @output_dir, batch_size: 2).generate_for_scope(Property.where(id: [property.id, *other_properties.map(&:id)]))

    expect(report).to include(
      batch_size: 2,
      batches: 2,
      processed: 3
    )
    expect(report.fetch(:results).map { |result| result[:batch_number] }).to eq([1, 1, 2])
  end

  it "skips properties that already have any hero image unless forced" do
    FactoryBot.create(:photo, property:, image_filename: "already-present.jpg", primary: true, position: 1)

    result = described_class.new(client: fake_client, output_dir: @output_dir).generate_for_property(property)

    expect(result[:status]).to eq(:skipped)
    expect(result[:reason]).to eq("existing_image_preserved")
  end

  it "preserves an existing primary photo by default" do
    existing_photo = FactoryBot.create(
      :photo,
      property:,
      image_filename: "old-front.jpg",
      caption: "Old caption",
      primary: true,
      position: 1
    )

    result = described_class.new(client: fake_client, output_dir: @output_dir).generate_for_property(property)

    expect(result[:status]).to eq(:skipped)
    expect(property.reload.photos.count).to eq(1)
    expect(existing_photo.reload).to have_attributes(
      image_filename: "old-front.jpg",
      caption: "Old caption",
      primary: true,
      position: 1
    )
  end

  it "can replace existing imagery when force is enabled" do
    existing_photo = FactoryBot.create(
      :photo,
      property:,
      image_filename: "already-present.jpg",
      caption: "Old caption",
      primary: true,
      position: 1
    )

    result = described_class.new(client: fake_client, output_dir: @output_dir, force: true).generate_for_property(property)

    expect(result[:status]).to eq(:generated)
    expect(existing_photo.reload.image_filename).to eq(generated_filename)
  end
end
