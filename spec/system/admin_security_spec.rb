require "rails_helper"

RSpec.describe "Admin security", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  let(:password) { "changeme" }

  around do |example|
    travel_to(Time.zone.local(2026, 4, 6, 10, 0)) { example.run }
  end

  def sign_in_as(admin, otp_attempt: nil)
    visit admin_security_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: password
    fill_in "admin_otp_attempt", with: otp_attempt if otp_attempt.present?
    click_button "Sign in"
  end

  def enroll_admin!(admin)
    secret = Admin.generate_otp_secret
    admin.update!(otp_secret: secret, otp_required_for_login: true, consumed_timestep: nil)
    backup_codes = admin.generate_otp_backup_codes!
    admin.save!
    [secret, backup_codes]
  end

  it "enrolls an admin with a QR setup flow and reveals fresh backup codes" do
    admin = FactoryBot.create(:admin, email: "security-admin@gotthekeys.com", password:, password_confirmation: password)
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    sign_in_as(admin)

    expect(page).to have_text("Admin security")
    expect(page).to have_text("Not enrolled")

    click_button "Begin setup"

    expect(page).to have_css('[data-testid="admin-security-qr"] svg')

    manual_key = find('[data-testid="admin-security-manual-key"]').text.strip
    otp_attempt = ROTP::TOTP.new(manual_key).at(Time.current)

    fill_in "Verification code", with: otp_attempt
    click_button "Confirm and enable 2FA"

    expect(page).to have_text("Two-factor authentication is now enabled for this admin.")
    expect(page).to have_css('[data-testid="admin-security-backup-codes-panel"]')
    expect(page).to have_css('[data-testid="admin-security-backup-codes"]')
    expect(page).to have_no_css('[data-testid="flash-admin_security_backup_codes"]')
    expect(page).to have_css('[data-testid="admin-security-backup-code"]', count: Admin.otp_number_of_backup_codes)
    expect(page).to have_text("Enrolled")

    admin.reload
    expect(admin.two_factor_enrolled?).to be(true)
    expect(admin.otp_backup_codes.count).to eq(Admin.otp_number_of_backup_codes)
    expect(admin.audit_logs.where(action: "admin_two_factor_enrollment_completed")).to exist
  end

  it "lets an admin disable their own 2FA without affecting the global rollback switch" do
    admin = FactoryBot.create(:admin, email: "disable-admin@gotthekeys.com", password:, password_confirmation: password)
    enroll_admin!(admin)
    BookingConfiguration.current.update!(admin_two_factor_mode: "disabled")

    sign_in_as(admin)

    expect(page).to have_text("Enrolled")

    click_button "Disable two-factor"

    expect(page).to have_text("Two-factor authentication has been disabled for this admin.")
    expect(page).to have_text("Not enrolled")

    admin.reload
    expect(admin.otp_secret).to be_nil
    expect(admin.stored_otp_required_for_login?).to be(false)
    expect(admin.otp_backup_codes).to eq([])
    expect(admin.audit_logs.where(action: "admin_two_factor_disabled")).to exist
  end
end
