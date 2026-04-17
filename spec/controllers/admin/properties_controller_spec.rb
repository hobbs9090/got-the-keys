require "rails_helper"

RSpec.describe Admin::PropertiesController, type: :controller do
  describe "#filtered_properties" do
    it "builds a postgres-safe relation without DISTINCT before recommended ordering" do
      relation = controller.send(:filtered_properties).recommended_order

      expect(relation.to_sql).not_to match(/\bSELECT DISTINCT\b/i)
    end
  end
end
