require "rails_helper"

RSpec.describe Api::V1::PropertySummaryResource do
  describe ".render" do
    it "formats asking price values as whole pounds" do
      property = build_stubbed(:property, asking_price: 600_000)

      payload = described_class.render(property, host: "https://example.test", next_slot: nil)

      expect(payload[:asking_price_pence]).to eq(600_000)
      expect(payload[:asking_price_display]).to eq("£600,000")
    end
  end
end
