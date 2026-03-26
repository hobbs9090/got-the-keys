module StatisticsHelper
  def statistics_chart_tag(chart_id:, chart_type:, data:, options:, class_name: nil)
    tag.div(
      "",
      id: chart_id,
      class: ["statistics-chart", class_name].compact.join(" "),
      data: {
        statistics_chart: true,
        chart_type: chart_type,
        chart_data: data.to_json,
        chart_options: options.to_json
      }
    )
  end
end
