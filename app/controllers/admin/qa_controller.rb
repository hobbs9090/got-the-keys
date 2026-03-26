class Admin::QaController < Admin::BaseController
  def show
    index
    render :index
  end

  def index
    catalog = DemoData::ScenarioCatalog.new
    @scenarios = catalog.all
    @baseline = catalog.fetch!("baseline")
    @scenario_previews = DemoData::ScenarioLoader.new.scenarios
    @scenario_family_groups = @scenario_previews.group_by { |scenario| scenario.dig(:qa, :family) }
    @diagnostics = Qa::DiagnosticsSnapshot.new(catalog:).to_h.merge(
      properties: Property.count,
      users: User.count,
      bookings: Appointment.count,
      notification_logs: NotificationLog.count,
      last_demo_action: DemoScenarioRun.recent_first.first
    )
    @selector_groups = Qa::SelectorRegistry.new.grouped_by_surface
    @training_journeys = I18n.t("ui.admin.qa.training_journeys")
  end
end
