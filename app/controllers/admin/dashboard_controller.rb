class Admin::DashboardController < Admin::BaseController
  def show
    index
    render :index
  end

  def index
    @pending_appointments = Appointment.pending_action.limit(6)
    @upcoming_appointments = Appointment.upcoming.limit(8)
    @recent_appointments = Appointment.recent_first.limit(8)
    @recent_enquiries = Enquiry.recent_first.limit(6)
    @notification_logs = NotificationLog.recent_first.limit(6)
    @latest_demo_run = DemoScenarioRun.recent_first.first
    @metrics = Rails.cache.fetch(dashboard_metrics_cache_key, expires_in: 5.minutes) { dashboard_metrics }
  end

  private

  def dashboard_metrics
    {
      properties: Property.count,
      properties_requiring_review: Property.where(listing_state: "review_pending").count,
      upcoming_appointments: Appointment.upcoming.count,
      pending_actions: Appointment.pending_action.count,
      offers: Offer.count,
      customers: Appointment.distinct.count(:customer_email),
      open_leads: Enquiry.open_pipeline.count
    }
  end

  def dashboard_metrics_cache_key
    [
      "admin/dashboard/metrics",
      Property.all.cache_key_with_version,
      Appointment.all.cache_key_with_version,
      Offer.all.cache_key_with_version,
      Enquiry.all.cache_key_with_version
    ]
  end
end
