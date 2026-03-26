require "rails_helper"

RSpec.describe Qa::SelectorRegistry do
  it "loads selector contracts from configuration" do
    registry = described_class.new

    expect(registry.all).to include(
      include(
        key: "property_card",
        surface: "Public catalogue",
        selector: 'data-testid="property-card"'
      )
    )
    expect(registry.grouped_by_surface.fetch("Admin shell").first[:key]).to eq("active_demo_scenario")
  end
end
