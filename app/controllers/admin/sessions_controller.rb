class Admin::SessionsController < Devise::SessionsController
  def create
    if two_factor_challenge_token_param.present?
      complete_two_factor_challenge
      return
    end

    if missing_two_factor_attempt?
      @admin_two_factor_challenge_token = issue_two_factor_challenge_token(pending_two_factor_candidate)
      self.resource = resource_class.new(email: sign_in_params[:email].to_s, otp_attempt: sign_in_params[:otp_attempt].to_s)
      resource.errors.add(:otp_attempt, t("devise.failure.admin_otp_attempt_missing"))
      clean_up_passwords(resource)
      render "devise/sessions/new", status: :unprocessable_content
      return
    end

    super
  end

  private

  def complete_two_factor_challenge
    @admin_two_factor_challenge_token = two_factor_challenge_token_param
    admin = admin_from_two_factor_challenge_token(@admin_two_factor_challenge_token)
    otp_attempt = sign_in_params[:otp_attempt].to_s.strip

    self.resource = resource_class.new(email: admin&.email.to_s, otp_attempt: sign_in_params[:otp_attempt].to_s)

    if admin.blank?
      resource.errors.add(:base, t("devise.failure.invalid", authentication_keys: "email"))
      clean_up_passwords(resource)
      render "devise/sessions/new", status: :unprocessable_content
      return
    end

    if otp_attempt.blank?
      resource.errors.add(:otp_attempt, t("devise.failure.admin_otp_attempt_missing"))
      clean_up_passwords(resource)
      render "devise/sessions/new", status: :unprocessable_content
      return
    end

    unless admin.validate_and_consume_otp!(otp_attempt)
      resource.errors.add(:otp_attempt, t("ui.admin.security.invalid_code"))
      clean_up_passwords(resource)
      render "devise/sessions/new", status: :unprocessable_content
      return
    end

    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, admin)
    respond_with admin, location: after_sign_in_path_for(admin)
  end

  def issue_two_factor_challenge_token(admin)
    verifier.generate(
      {
        admin_id: admin.id,
        issued_at: Time.current.to_i
      }
    )
  end

  def admin_from_two_factor_challenge_token(token)
    payload = verifier.verify(token)
    issued_at_value = payload[:issued_at] || payload["issued_at"]
    admin_id = payload[:admin_id] || payload["admin_id"]
    return if issued_at_value.blank? || admin_id.blank?

    issued_at = Time.zone.at(issued_at_value.to_i)
    return if issued_at < 10.minutes.ago

    admin = resource_class.find_by(id: admin_id)
    return if admin.blank?
    return unless admin.two_factor_required_for_sign_in?

    admin
  rescue ActiveSupport::MessageVerifier::InvalidSignature, TypeError
    nil
  end

  def verifier
    Rails.application.message_verifier("admin-two-factor-sign-in")
  end

  def two_factor_challenge_token_param
    params.fetch(resource_name, {}).fetch(:two_factor_challenge_token, "").to_s
  end

  def missing_two_factor_attempt?
    return false unless sign_in_params[:otp_attempt].to_s.strip.blank?

    pending_two_factor_candidate.present?
  end

  def pending_two_factor_candidate
    admin = resource_class.find_for_database_authentication(email: sign_in_params[:email].to_s)
    return if admin.blank?
    return unless admin.valid_password?(sign_in_params[:password].to_s)
    return unless admin.two_factor_required_for_sign_in?

    admin
  end
end
