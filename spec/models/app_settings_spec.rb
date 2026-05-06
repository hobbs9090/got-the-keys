require "rails_helper"

RSpec.describe AppSettings do
  let(:settings) { Rails.configuration.x.got_the_keys }

  around do |example|
    original_languages = settings.available_languages
    original_exchange_rate = settings.exchange_rate_gbp_to_cny

    example.run
  ensure
    settings.available_languages = original_languages
    settings.exchange_rate_gbp_to_cny = original_exchange_rate
  end

  it "returns the configured available languages" do
    settings.available_languages = %w[en zh fr]

    expect(described_class.available_languages).to eq(%w[en zh fr])
  end

  it "returns the configured GBP to CNY exchange rate" do
    settings.exchange_rate_gbp_to_cny = 9.99

    expect(described_class.exchange_rate_gbp_to_cny).to eq(9.99)
  end

  it "returns the default branch profile" do
    expect(described_class.primary_branch_profile).to include(
      name: "Sevenoaks and Westerham office",
      email: "hello@gotthekeys.uk"
    )
  end
end
