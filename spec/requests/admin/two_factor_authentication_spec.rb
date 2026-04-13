require "rails_helper"

RSpec.describe "Admin two-factor authentication", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { "changeme" }
  let(:admin) { FactoryBot.create(:admin, email: "two-factor-admin@gotthekeys.com", password:, password_confirmation: password) }

  around do |example|
    travel_to(Time.zone.local(2026, 4, 6, 10, 0)) { example.run }
  end

  def enroll_admin!(record)
    secret = Admin.generate_otp_secret
    record.update!(otp_secret: secret, otp_required_for_login: true, consumed_timestep: nil)
    backup_codes = record.generate_otp_backup_codes!
    record.save!
    [secret, backup_codes]
  end

  def sign_in_admin(otp_attempt: nil, include_password: true)
    params = { admin: { email: admin.email } }
    params[:admin][:password] = password if include_password
    params[:admin][:otp_attempt] = otp_attempt if otp_attempt.present?
    post admin_session_path, params:
  end

  def current_otp_for(secret)
    ROTP::TOTP.new(secret).at(Time.current)
  end

  it "allows an enrolled admin to sign in without an OTP while the global mode is disabled" do
    secret, = enroll_admin!(admin)
    BookingConfiguration.current.update!(admin_two_factor_mode: "disabled")

    sign_in_admin

    expect(response).to redirect_to(admin_root_path)

    follow_redirect!

    expect(response.body).to include("Signed in successfully as Admin.")
    expect(admin.reload.otp_secret).to eq(secret)
    expect(admin.reload.stored_otp_required_for_login?).to be(true)
  end

  it "allows an unenrolled admin to sign in when the global mode is optional" do
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    sign_in_admin

    expect(response).to redirect_to(admin_root_path)
  end

  it "requires a valid OTP when the global mode is optional and the admin is enrolled" do
    secret, = enroll_admin!(admin)
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    sign_in_admin

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Enter your verification code or a backup code to finish signing in.")
    expect(response.body).to include("Password verified. Enter your code to continue.")
    expect(response.body).to include("Verification code or backup code")
    expect(response.body).to include("Enter an authenticator code or one of your backup codes.")
    expect(response.body).not_to include('name="admin[password]"')
    expect(response.body).not_to include("Invalid email or password.")
    expect(response.body).not_to include("error prohibited this admin from being saved")

    sign_in_admin(otp_attempt: current_otp_for(secret))

    expect(response).to redirect_to(admin_root_path)
  end

  it "treats a blank OTP field as a missing code when the password is otherwise correct" do
    enroll_admin!(admin)
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    post admin_session_path, params: { admin: { email: admin.email, password:, otp_attempt: "" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Enter your verification code or a backup code to finish signing in.")
    expect(response.body).not_to include("Invalid email or password.")
    expect(response.body).not_to include("error prohibited this admin from being saved")
  end

  it "accepts backup codes once each" do
    _secret, backup_codes = enroll_admin!(admin)
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    sign_in_admin(otp_attempt: backup_codes.first)

    expect(response).to redirect_to(admin_root_path)
    expect(admin.reload.otp_backup_codes.count).to eq(Admin.otp_number_of_backup_codes - 1)

    delete destroy_admin_session_path

    sign_in_admin(otp_attempt: backup_codes.first)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Invalid email or password.")
  end

  it "restores OTP enforcement when the global mode moves from optional to disabled and back again" do
    secret, = enroll_admin!(admin)
    booking_configuration = BookingConfiguration.current

    booking_configuration.update!(admin_two_factor_mode: "optional")
    sign_in_admin
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Enter your verification code or a backup code to finish signing in.")
    expect(response.body).not_to include("error prohibited this admin from being saved")

    booking_configuration.update!(admin_two_factor_mode: "disabled")
    sign_in_admin
    expect(response).to redirect_to(admin_root_path)

    delete destroy_admin_session_path

    booking_configuration.update!(admin_two_factor_mode: "optional")
    sign_in_admin
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Enter your verification code or a backup code to finish signing in.")
    expect(response.body).not_to include("error prohibited this admin from being saved")

    sign_in_admin(otp_attempt: current_otp_for(secret))
    expect(response).to redirect_to(admin_root_path)
  end
end
