module Admin::DashboardHelper
  def admin_dashboard_metric_path(metric_key)
    case metric_key.to_sym
    when :properties
      admin_properties_path
    when :properties_requiring_review
      admin_properties_path(listing_state: "review_pending")
    when :upcoming_appointments
      admin_appointments_path(view: "agenda")
    when :pending_actions
      admin_appointments_path(view: "agenda", queue: "pending_action")
    when :offers
      admin_sales_path
    when :customers
      admin_customers_path
    when :open_leads
      admin_leads_path
    else
      admin_root_path
    end
  end
end
