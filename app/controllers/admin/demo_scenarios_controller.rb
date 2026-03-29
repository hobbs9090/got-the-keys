class Admin::DemoScenariosController < Admin::BaseController
  before_action :load_scenario_loader
  before_action :ensure_baseline_admin_scenario!, only: %i[show apply]

  def index
    @baseline_scenario = @scenario_loader.preview("baseline")
    @latest_run = DemoScenarioRun.recent_first.first
    @diagnostics = diagnostics_payload
  end

  def show
    @preview = @scenario_loader.preview("baseline")
  end

  def apply
    restore_baseline
  end

  def restore_baseline
    scenario = @scenario_loader.preview("baseline")
    return if reject_unconfirmed_demo_scenario!(scenario)

    actor_email = current_admin.email
    summary = @scenario_loader.apply_catalog!(key: "baseline", actor_email:)
    reauthenticate_admin(actor_email)

    redirect_to admin_demo_scenarios_path, notice: t("ui.admin.flash.restored_baseline_demo_scenario", name: summary.fetch(:name))
  rescue StandardError => error
    redirect_to admin_demo_scenarios_path, alert: error.message
  end

  def import
  end

  def preview_import
    @raw_yaml = imported_yaml_source
    @preview = @scenario_loader.preview_yaml(@raw_yaml)
    session[:demo_scenario_import_yaml] = @raw_yaml
    render :import_preview
  rescue StandardError => error
    redirect_to import_admin_demo_scenarios_path, alert: error.message
  end

  def apply_import
    raw_yaml = session[:demo_scenario_import_yaml]
    actor_email = current_admin.email
    summary = @scenario_loader.apply_yaml!(yaml_source: raw_yaml, actor_email:)
    session.delete(:demo_scenario_import_yaml)
    reauthenticate_admin(actor_email)

    redirect_to admin_demo_scenarios_path, notice: t("ui.admin.flash.imported_demo_scenario", name: summary.fetch(:name))
  rescue StandardError => error
    redirect_to import_admin_demo_scenarios_path, alert: error.message
  end

  def export
    send_data @scenario_loader.export, filename: "gotthekeys-demo-snapshot-#{Date.current.iso8601}.yml", type: "text/yaml"
  end

  private

  def load_scenario_loader
    @scenario_loader = DemoData::ScenarioLoader.new
  end

  def imported_yaml_source
    params[:scenario_yaml].presence || params.dig(:demo_import, :scenario_yaml).presence || uploaded_yaml_source
  end

  def uploaded_yaml_source
    upload = params.dig(:demo_import, :scenario_file)
    upload&.read
  end

  def diagnostics_payload
    {
      active_scenario: booking_configuration.active_demo_scenario_key,
      property_count: Property.count,
      user_count: User.count,
      appointment_count: Appointment.count,
      enquiry_count: Enquiry.count,
      notification_count: NotificationLog.count,
      last_demo_action: DemoScenarioRun.recent_first.first&.created_at,
      mail_delivery_mode: ActionMailer::Base.delivery_method.to_s,
      job_adapter: ActiveJob::Base.queue_adapter.class.name.demodulize.underscore
    }
  end

  def reject_unconfirmed_demo_scenario!(scenario)
    return false unless scenario.dig(:qa, :quick_reset)
    return false if params[:confirm_demo_scenario].to_s == scenario.fetch(:key).to_s

    redirect_to(
      demo_scenario_return_path(scenario.fetch(:key)),
      alert: t("ui.admin.flash.demo_scenario_confirmation_required", phrase: scenario.fetch(:key))
    )

    true
  end

  def demo_scenario_return_path(scenario_key)
    preview_path = admin_demo_scenario_path(scenario_key)
    requested_path = params[:return_to].to_s

    return requested_path if [admin_demo_scenarios_path, preview_path].include?(requested_path)

    admin_demo_scenarios_path
  end

  def reauthenticate_admin(email)
    replacement_admin = Admin.find_by(email: email)
    bypass_sign_in(replacement_admin) if replacement_admin.present?
  end

  def ensure_baseline_admin_scenario!
    return if params[:id].to_s == "baseline"

    redirect_to(
      admin_demo_scenarios_path,
      alert: t("ui.admin.demo_data.baseline_only_alert", default: "Only the baseline demo dataset is available here right now.")
    )
  end
end
