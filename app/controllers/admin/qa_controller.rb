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
    @training_journeys = [
      "Create a new booking from a property page and verify the success message plus reference code.",
      "As an admin, confirm a pending appointment and validate the status badge plus audit timeline.",
      "Reschedule an appointment into an occupied slot and verify the conflict validation message.",
      "Restore the baseline dataset, then switch to the fully booked scenario and verify the empty-slot state.",
      "Export the current dataset, import it back through the preview screen, and confirm the diagnostics panel updates."
    ]
  end
end
