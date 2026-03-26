class Admin::NotificationLogsController < Admin::BaseController
  def index
    @notification_logs = NotificationLog.recent_first.includes(appointment: :property, enquiry: :property).page(params[:page])
  end
end
