class Admin::SessionsController < Devise::SessionsController
  def create
    if missing_two_factor_attempt?
      self.resource = resource_class.new(email: sign_in_params[:email].to_s, otp_attempt: sign_in_params[:otp_attempt].to_s)
      resource.errors.add(:otp_attempt, t("devise.failure.admin_otp_attempt_missing"))
      clean_up_passwords(resource)
      render "devise/sessions/new", status: :unprocessable_content
      return
    end

    super
  end

  private

  def missing_two_factor_attempt?
    return false unless sign_in_params[:otp_attempt].to_s.strip.blank?

    admin = resource_class.find_for_database_authentication(email: sign_in_params[:email].to_s)
    return false if admin.blank?
    return false unless admin.valid_password?(sign_in_params[:password].to_s)

    admin.two_factor_required_for_sign_in?
  end
end
