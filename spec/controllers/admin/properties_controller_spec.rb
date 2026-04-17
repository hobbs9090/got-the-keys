require "rails_helper"

RSpec.describe Admin::PropertiesController, type: :controller do
  describe "#filtered_properties" do
    it "builds a postgres-safe relation without DISTINCT before recommended ordering" do
      controller.instance_variable_set(:@query, nil)
      controller.instance_variable_set(:@listing_state, nil)
      controller.instance_variable_set(:@sale_status, nil)
      controller.instance_variable_set(:@town_city, nil)
      controller.instance_variable_set(:@min_bedrooms, nil)
      controller.instance_variable_set(:@min_price, nil)
      controller.instance_variable_set(:@max_price, nil)

      relation = controller.send(:filtered_properties).recommended_order

      expect(relation.to_sql).not_to match(/\bSELECT DISTINCT\b/i)
    end
  end
end
