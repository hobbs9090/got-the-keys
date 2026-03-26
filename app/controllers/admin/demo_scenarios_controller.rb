class Admin::DemoScenariosController < Admin::BaseController
  before_action :load_scenario_loader

  def index
    @scenarios = @scenario_loader.scenarios
    @latest_run = DemoScenarioRun.recent_first.first
    @diagnostics = diagnostics_payload
  end

  def show
    @preview = @scenario_loader.preview(params[:id])
  end

  def apply
    actor_email = current_admin.email
    summary = @scenario_loader.apply_catalog!(key: params[:id], actor_email:)
    reauthenticate_admin(actor_email)

    redirect_to admin_demo_scenarios_path, notice: t("ui.admin.flash.applied_demo_scenario", name: summary.fetch(:name))
  rescue StandardError => error
    redirect_to admin_demo_scenarios_path, alert: error.message
  end

  def restore_baseline
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
      last_demo_action: DemoScenarioRun.recent_first.first&.created_at
    }
  end

  def reauthenticate_admin(email)
    replacement_admin = Admin.find_by(email: email)
    bypass_sign_in(replacement_admin) if replacement_admin.present?
  end
end
