class Admin::QaController < Admin::BaseController
  ADMIN_TWO_FACTOR_DISABLE_CONFIRMATION = "DISABLE".freeze

  helper_method :admin_two_factor_disable_confirmation_phrase

  def show
    load_page_data
    render :index
  end

  def update
    @booking_configuration ||= booking_configuration
    previous_mode = @booking_configuration.admin_two_factor_mode
    @booking_configuration.assign_attributes(admin_two_factor_mode: admin_two_factor_mode_params[:admin_two_factor_mode])

    if disabling_without_confirmation?(previous_mode)
      @booking_configuration.errors.add(:admin_two_factor_mode, t("ui.admin.qa.admin_two_factor.confirmation_required"))
      load_page_data
      render :index, status: :unprocessable_content
      return
    end

    if @booking_configuration.save
      audit_admin_two_factor_mode_change!(from: previous_mode, to: @booking_configuration.admin_two_factor_mode) if previous_mode != @booking_configuration.admin_two_factor_mode
      redirect_to admin_qa_path, notice: t("ui.admin.qa.admin_two_factor.updated_notice")
    else
      load_page_data
      render :index, status: :unprocessable_content
    end
  end

  private

  def load_page_data
    catalog = DemoData::ScenarioCatalog.new
    @scenarios = catalog.all
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
    @booking_configuration ||= booking_configuration
    @last_admin_two_factor_mode_change = AuditLog.recent_first.find_by(action: "admin_two_factor_mode_changed")
  end

  def admin_two_factor_mode_params
    params.fetch(:booking_configuration, {}).permit(:admin_two_factor_mode)
  end

  def admin_two_factor_disable_confirmation_phrase
    ADMIN_TWO_FACTOR_DISABLE_CONFIRMATION
  end

  def disabling_without_confirmation?(previous_mode)
    previous_mode != "disabled" &&
      @booking_configuration.admin_two_factor_disabled? &&
      disable_confirmation_value != admin_two_factor_disable_confirmation_phrase
  end

  def disable_confirmation_value
    params[:confirm_disable_admin_two_factor].to_s.strip.upcase
  end

  def audit_admin_two_factor_mode_change!(from:, to:)
    AuditLogger.log!(
      auditable: booking_configuration,
      admin: current_admin,
      action: "admin_two_factor_mode_changed",
      message: "Admin two-factor mode changed from #{from} to #{to}.",
      metadata: { from:, to: }
    )
  end
end
