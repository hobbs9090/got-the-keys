class Admin::DemoScenariosController < Admin::BaseController
  before_action :load_scenario_loader
  before_action :ensure_baseline_admin_scenario!, only: %i[show apply]

  PERFORMANCE_SEED_DEFAULTS = {
    user_count: DemoData::Populator::DEFAULT_USER_COUNT,
    property_count: DemoData::Populator::DEFAULT_PROPERTY_COUNT,
    password: "secret1234",
    ai_mode: "off",
    batch_size: DemoData::Populator::DEFAULT_BATCH_SIZE,
    model: DemoData::OpenaiEnrichmentModels::DEFAULT
  }.freeze

  def index
    load_dashboard_state
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

  def populate_performance
    form = normalized_performance_seed_form
    summary = DemoData::Populator.new(
      user_count: form.fetch(:user_count),
      property_count: form.fetch(:property_count),
      password: form.fetch(:password),
      ai_mode: DemoData::Populator.ai_mode_from_env(form.fetch(:ai_mode)),
      batch_size: form.fetch(:batch_size),
      model: form.fetch(:model),
      logger: Rails.logger
    ).populate!

    DemoScenarioRun.create!(
      scenario_key: BookingConfiguration.current.active_demo_scenario_key,
      action_type: "populate",
      initiated_by_email: current_admin.email,
      source: "populate",
      summary_data: {
        users_added: summary.fetch(:users_used),
        properties_added: summary.fetch(:properties_created),
        total_user_count: User.count,
        total_property_count: Property.count,
        password_hint: t("ui.admin.demo_data.performance_seed.password_summary", default: "Uses the password entered when the job was run."),
        ai_mode: summary.fetch(:ai_mode).to_s,
        model: summary.fetch(:model) || form.fetch(:model),
        batch_size: form.fetch(:batch_size)
      }
    )

    redirect_to(
      admin_demo_scenarios_path,
      notice: t("ui.admin.flash.populated_performance_demo_data", users: summary.fetch(:users_used), properties: summary.fetch(:properties_created))
    )
  rescue StandardError => error
    load_dashboard_state(form_values: performance_seed_form_values)
    flash.now[:alert] = error.message
    render :index, status: :unprocessable_content
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

  def load_dashboard_state(form_values: nil)
    @baseline_scenario = @scenario_loader.preview("baseline")
    @performance_seed_form = PERFORMANCE_SEED_DEFAULTS.merge(form_values || {})
    @scenario_runs = DemoScenarioRun.recent_first.limit(10)
  end

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

  def performance_seed_form_values
    params.fetch(:performance_seed, {}).permit(:user_count, :property_count, :password, :ai_mode, :batch_size, :model).to_h.symbolize_keys
  end

  def normalized_performance_seed_form
    values = PERFORMANCE_SEED_DEFAULTS.merge(performance_seed_form_values)

    {
      user_count: normalized_integer!(values[:user_count], field: :user_count, minimum: 1),
      property_count: normalized_integer!(values[:property_count], field: :property_count, minimum: 0),
      password: normalized_string!(values[:password], field: :password),
      ai_mode: normalized_ai_mode!(values[:ai_mode]),
      batch_size: normalized_integer!(values[:batch_size], field: :batch_size, minimum: 1),
      model: normalized_model!(values[:model])
    }
  end

  def normalized_integer!(value, field:, minimum:)
    integer = Integer(value)
  rescue ArgumentError, TypeError
    raise ArgumentError, t("ui.admin.demo_data.performance_seed.validation.integer", field: performance_seed_field_label(field))
  else
    raise ArgumentError, t("ui.admin.demo_data.performance_seed.validation.integer_minimum", field: performance_seed_field_label(field), minimum:) if integer < minimum

    integer
  end

  def normalized_string!(value, field:)
    string = value.to_s.strip
    raise ArgumentError, t("ui.admin.demo_data.performance_seed.validation.required", field: performance_seed_field_label(field)) if string.blank?

    string
  end

  def normalized_ai_mode!(value)
    mode = value.to_s.strip.downcase
    return mode if %w[off auto on].include?(mode)

    raise ArgumentError, t("ui.admin.demo_data.performance_seed.validation.ai_mode")
  end

  def normalized_model!(value)
    model = normalized_string!(value, field: :model)
    return model if DemoData::OpenaiEnrichmentModels::AVAILABLE.include?(model)

    raise ArgumentError, t("ui.admin.demo_data.performance_seed.validation.model")
  end

  def performance_seed_field_label(field)
    t("ui.admin.demo_data.performance_seed.fields.#{field}")
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
