require 'rails_helper'

RSpec.describe DemoData::PropertyBlueprintGenerator do
  subject(:generator) { described_class.new(random: Random.new(12_345)) }

  it 'builds realistic property attributes that satisfy model constraints' do
    blueprint = generator.build(index: 1)

    property = Property.new(blueprint.except(:prompt_context).merge(user: FactoryBot.create(:user)))

    expect(property).to be_valid
    expect(property.country).to eq('United Kingdom')
    expect(%w[For\ Sale For\ Rent]).to include(property.sale_status)
    expect(property.asking_price).to be >= 750
    expect(blueprint[:postcode]).to match(/\A[A-Z]{1,2}\d[A-Z\d]? \d[A-Z]{2}\z/)
    expect(blueprint[:address_line_1]).to match(/\A(?:(?:Flat|Apartment|Maisonette) \d+, )?\d+ .+\z/)
    expect(blueprint[:town_city]).to be_in(described_class::AREA_CATALOG.map { |area| area.fetch(:town_city) })
    expect(blueprint[:listing_tagline]).to be_present
    expect(property.property_description.length).to be >= 25
  end
end
