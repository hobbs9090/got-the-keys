require "rails_helper"

RSpec.describe StatisticsHelper, type: :helper do
  describe "#statistics_chart_tag" do
    it "renders a chart placeholder with serialized data attributes" do
      fragment = Nokogiri::HTML.fragment(
        helper.statistics_chart_tag(
          chart_id: "property-size-chart",
          chart_type: "bar",
          data: [["Bedrooms", "Total"], ["2 bed", 8]],
          options: { title: "Property sizes" },
          class_name: "statistics-chart--wide"
        )
      )

      chart = fragment.at_css("div#property-size-chart")

      expect(chart).to be_present
      expect(chart["class"]).to include("statistics-chart")
      expect(chart["class"]).to include("statistics-chart--wide")
      expect(chart["data-statistics-chart"]).to eq("true")
      expect(chart["data-chart-type"]).to eq("bar")
      expect(JSON.parse(chart["data-chart-data"])).to eq([["Bedrooms", "Total"], ["2 bed", 8]])
      expect(JSON.parse(chart["data-chart-options"])).to eq({ "title" => "Property sizes" })
    end
  end
end
