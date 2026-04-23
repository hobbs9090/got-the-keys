class Admin::QaController < Admin::BaseController
  def show
    load_page_data
    render :index
  end

  private

  def load_page_data
    catalog = DemoData::ScenarioCatalog.new
    @scenarios = catalog.all
    @scenario_previews = DemoData::ScenarioLoader.new.scenarios
    @scenario_family_groups = @scenario_previews.group_by { |scenario| scenario.dig(:qa, :family) }
    @diagnostics = Qa::DiagnosticsSnapshot.new(catalog:)
      .to_h
      .except(:build_version, :git_sha, :build_number, :environment)
      .merge(
        properties: Property.count,
        users: User.count,
        bookings: Appointment.count,
        notification_logs: NotificationLog.count,
        last_demo_action: DemoScenarioRun.recent_first.first
      )
    @selector_groups = Qa::SelectorRegistry.new.grouped_by_surface
  end
end
