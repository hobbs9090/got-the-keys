require 'rails_helper'

RSpec.describe DemoData::OpenaiPropertyEnhancer do
  let(:response_body) do
    {
      properties: [
        {
          asking_price: 612_000,
          property_description: 'A polished three-bedroom family home with bright reception space, a practical kitchen, and easy access to rail links and everyday amenities.'
        }
      ]
    }.to_json
  end

  let(:fake_client) do
    Class.new do
      attr_reader :responses

      def initialize(body)
        @responses = Class.new do
          def initialize(response)
            @response = response
          end

          def create(*)
            @response
          end
        end.new(Struct.new(:output_text).new(body))
      end
    end.new(response_body)
  end

  it 'merges enriched OpenAI output back into the local blueprint' do
    blueprint = DemoData::PropertyBlueprintGenerator.new(random: Random.new(9)).build(index: 0).merge(
      sale_status: 'For Sale',
      asking_price: 590_000
    )

    enriched = described_class.new(client: fake_client).enhance_batch([blueprint]).first

    expect(enriched[:asking_price]).to eq(612_000)
    expect(enriched[:property_description]).to include('family home')
    expect(enriched[:town_city]).to eq(blueprint[:town_city])
  end
end
