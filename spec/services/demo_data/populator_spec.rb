require 'rails_helper'

RSpec.describe DemoData::Populator do
  let(:users) { FactoryBot.create_list(:user, 2) }

  it 'creates properties for provided users without requiring OpenAI' do
    result = nil

    expect do
      result = described_class.new(
        users: users,
        property_count: 5,
        ai_mode: :off,
        blueprint_generator: DemoData::PropertyBlueprintGenerator.new(random: Random.new(55))
      ).populate!
    end.to change(Property, :count).by(5)

    expect(result[:properties_created]).to eq(5)
    expect(result[:users_used]).to eq(2)
    expect(Property.order(:id).last(5).map(&:user_id).uniq.sort).to eq(users.map(&:id).sort)
  end

  it 'raises a clear error when AI mode is forced on without an API key' do
    climate_value = ENV.delete('OPENAI_API_KEY')

    expect do
      described_class.new(users: users, property_count: 1, ai_mode: :on).populate!
    end.to raise_error(ArgumentError, /OPENAI_API_KEY/)
  ensure
    ENV['OPENAI_API_KEY'] = climate_value if climate_value.present?
  end

  it 'creates English-focused seller accounts when generating users' do
    result = described_class.new(user_count: 4, property_count: 0, ai_mode: :off).populate!
    generated_users = User.order(:id).last(4)

    expect(result[:users_used]).to eq(4)
    expect(generated_users.pluck(:language).uniq).to eq(['en'])
    expect(generated_users.map(&:email)).to all(match(/\A[a-z]+(?:\.[a-z]+)+@(?:gmail|outlook|icloud|btinternet)\.example\z/))
    expect(generated_users.map(&:mobile_number)).to all(match(/\A07700 \d{6}\z/))
  end

  it 'can append generated users across multiple runs without reusing emails' do
    first_result = described_class.new(user_count: 2, property_count: 0, ai_mode: :off).populate!
    second_result = described_class.new(user_count: 2, property_count: 0, ai_mode: :off).populate!
    generated_users = User.order(:id).last(4)

    expect(first_result[:users_used]).to eq(2)
    expect(second_result[:users_used]).to eq(2)
    expect(generated_users.map(&:email).uniq.size).to eq(4)
  end
end
