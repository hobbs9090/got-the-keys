class Admin::DashboardController < Admin::BaseController
  def show
    index
    render :index
  end

  def index
    @pending_appointments = Appointment.pending_action.limit(6)
    @upcoming_appointments = Appointment.upcoming.limit(8)
    @recent_appointments = Appointment.recent_first.limit(8)
    @notification_logs = NotificationLog.recent_first.limit(6)
    @latest_demo_run = DemoScenarioRun.recent_first.first
    @metrics = {
      properties: Property.count,
      upcoming_appointments: Appointment.upcoming.count,
      pending_actions: Appointment.pending_action.count,
      customers: Appointment.distinct.count(:customer_email)
    }
  end
end
