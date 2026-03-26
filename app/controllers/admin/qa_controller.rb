class Admin::QaController < Admin::BaseController
  def show
    index
    render :index
  end

  def index
    catalog = DemoData::ScenarioCatalog.new
    @scenarios = catalog.all
    @baseline = catalog.fetch!("baseline")
    @diagnostics = {
      active_scenario: booking_configuration.active_demo_scenario_key,
      properties: Property.count,
      users: User.count,
      bookings: Appointment.count,
      notification_logs: NotificationLog.count,
      last_demo_action: DemoScenarioRun.recent_first.first
    }
    @training_journeys = I18n.t("ui.admin.qa.training_journeys")
  end
end
