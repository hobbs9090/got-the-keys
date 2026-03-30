class Admin::SecurityController < Admin::BaseController
  ADMIN_TWO_FACTOR_DISABLE_CONFIRMATION = "DISABLE".freeze
  SECURITY_AUDIT_ACTIONS = %w[
    admin_two_factor_enrollment_completed
    admin_two_factor_disabled
    admin_two_factor_backup_codes_regenerated
  ].freeze

  helper_method :admin_two_factor_disable_confirmation_phrase

  def show
    load_page_data
  end

  def update
    @booking_configuration = booking_configuration
    previous_mode = @booking_configuration.admin_two_factor_mode
    @booking_configuration.assign_attributes(admin_two_factor_mode: admin_two_factor_mode_params[:admin_two_factor_mode])

    if disabling_without_confirmation?(previous_mode)
      @booking_configuration.errors.add(:admin_two_factor_mode, t("ui.admin.qa.admin_two_factor.confirmation_required"))
      load_page_data
      render :show, status: :unprocessable_content
      return
    end

    if @booking_configuration.save
      audit_admin_two_factor_mode_change!(from: previous_mode, to: @booking_configuration.admin_two_factor_mode) if previous_mode != @booking_configuration.admin_two_factor_mode
      redirect_to admin_security_path, notice: t("ui.admin.qa.admin_two_factor.updated_notice")
    else
      load_page_data
      render :show, status: :unprocessable_content
    end
  end

  def enroll
    if current_admin.two_factor_enrolled?
      redirect_to admin_security_path, alert: t("ui.admin.security.already_enabled")
      return
    end

    session[:admin_pending_otp_secret] = Admin.generate_otp_secret
    redirect_to admin_security_path, notice: t("ui.admin.security.enrollment_started_notice")
  end

  def confirm
    load_page_data

    if @pending_otp_secret.blank?
      current_admin.errors.add(:base, t("ui.admin.security.enrollment_expired"))
      render :show, status: :unprocessable_content
      return
    end

    timestamp = verify_pending_otp(params.dig(:admin, :otp_attempt), @pending_otp_secret)

    if timestamp.blank?
      current_admin.errors.add(:otp_attempt, t("ui.admin.security.invalid_code"))
      render :show, status: :unprocessable_content
      return
    end

    backup_codes = []

    ActiveRecord::Base.transaction do
      current_admin.assign_attributes(
        otp_secret: @pending_otp_secret,
        otp_required_for_login: true,
        consumed_timestep: consumed_timestep_for(timestamp, @pending_otp_secret)
      )
      backup_codes = current_admin.generate_otp_backup_codes!
      current_admin.save!
    end

    AuditLogger.log!(
      auditable: current_admin,
      admin: current_admin,
      action: "admin_two_factor_enrollment_completed",
      message: "Completed admin two-factor enrollment.",
      metadata: { global_mode: booking_configuration.admin_two_factor_mode }
    )

    session.delete(:admin_pending_otp_secret)
    flash[:admin_security_backup_codes] = backup_codes
    redirect_to admin_security_path, notice: t("ui.admin.security.enabled_notice")
  end

  def regenerate_backup_codes
    unless current_admin.two_factor_enrolled?
      redirect_to admin_security_path, alert: t("ui.admin.security.not_enabled")
      return
    end

    backup_codes = []

    ActiveRecord::Base.transaction do
      backup_codes = current_admin.generate_otp_backup_codes!
      current_admin.save!
    end

    AuditLogger.log!(
      auditable: current_admin,
      admin: current_admin,
      action: "admin_two_factor_backup_codes_regenerated",
      message: "Regenerated admin two-factor backup codes."
    )

    flash[:admin_security_backup_codes] = backup_codes
    redirect_to admin_security_path, notice: t("ui.admin.security.backup_codes_regenerated_notice")
  end

  def disable
    unless current_admin.two_factor_enrolled?
      redirect_to admin_security_path, alert: t("ui.admin.security.not_enabled")
      return
    end

    current_admin.update!(
      otp_secret: nil,
      consumed_timestep: nil,
      otp_required_for_login: false,
      otp_backup_codes: []
    )
    session.delete(:admin_pending_otp_secret)

    AuditLogger.log!(
      auditable: current_admin,
      admin: current_admin,
      action: "admin_two_factor_disabled",
      message: "Disabled admin two-factor authentication."
    )

    redirect_to admin_security_path, notice: t("ui.admin.security.disabled_notice")
  end

  private

  def load_page_data
    @booking_configuration ||= booking_configuration
    @pending_otp_secret = current_admin.two_factor_enrolled? ? nil : session[:admin_pending_otp_secret].presence
    @fresh_backup_codes = Array(flash[:admin_security_backup_codes])
    @security_audit_logs = current_admin.audit_logs.where(action: SECURITY_AUDIT_ACTIONS).recent_first.limit(8)
    @last_admin_two_factor_mode_change = AuditLog.recent_first.find_by(action: "admin_two_factor_mode_changed")
  end

  def verify_pending_otp(code, secret)
    return if code.blank? || secret.blank?

    current_admin.otp(secret).verify(
      code.to_s.gsub(/\s+/, ""),
      drift_behind: Admin.otp_allowed_drift,
      drift_ahead: Admin.otp_allowed_drift
    )
  end

  def consumed_timestep_for(timestamp, secret)
    timestamp / current_admin.otp(secret).interval
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
