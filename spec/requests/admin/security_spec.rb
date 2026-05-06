require "rails_helper"
require "nokogiri"

RSpec.describe "Admin security" do
  let(:admin) { FactoryBot.create(:admin, email: "security-admin@gotthekeys.com", password: "changeme123", password_confirmation: "changeme123") }

  before do
    sign_in admin
  end

  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  it "shows personal 2FA status without the dead global-mode modal" do
    get admin_security_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-testid="admin-security-status-panel"))
    expect(response.body).not_to include(%(data-testid="admin-two-factor-mode-controls"))
    expect(response.body).not_to include(%(id="disable-admin-two-factor-mode-modal"))
  end

  it "updates the admin 2FA mode to optional and audits the change" do
    patch admin_security_path, params: { booking_configuration: { admin_two_factor_mode: "optional" } }

    expect(response).to redirect_to(admin_security_path)
    expect(BookingConfiguration.current.admin_two_factor_mode).to eq("optional")

    audit_log = AuditLog.recent_first.find_by(action: "admin_two_factor_mode_changed")
    expect(audit_log).to be_present
    expect(audit_log.admin).to eq(admin)
    expect(audit_log.metadata).to include("from" => "disabled", "to" => "optional")
  end

  it "requires explicit confirmation before switching admin 2FA to disabled" do
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    patch admin_security_path, params: { booking_configuration: { admin_two_factor_mode: "disabled" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(BookingConfiguration.current.admin_two_factor_mode).to eq("optional")
    expect(AuditLog.recent_first.find_by(action: "admin_two_factor_mode_changed")).to be_nil
  end

  it "switches admin 2FA back to disabled when the confirmation phrase is supplied" do
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    patch admin_security_path, params: {
      booking_configuration: { admin_two_factor_mode: "disabled" },
      confirm_disable_admin_two_factor: "DISABLE"
    }

    expect(response).to redirect_to(admin_security_path)
    expect(BookingConfiguration.current.admin_two_factor_mode).to eq("disabled")

    audit_log = AuditLog.recent_first.find_by(action: "admin_two_factor_mode_changed")
    expect(audit_log).to be_present
    expect(audit_log.metadata).to include("from" => "optional", "to" => "disabled")
  end

  context "when ADMIN_TWO_FACTOR_REQUIRED env var is set" do
    around do |example|
      ENV['ADMIN_TWO_FACTOR_REQUIRED'] = 'true'
      example.run
    ensure
      ENV.delete('ADMIN_TWO_FACTOR_REQUIRED')
    end

    it "rejects attempts to disable the global 2FA mode" do
      BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

      patch admin_security_path, params: {
        booking_configuration: { admin_two_factor_mode: "disabled" },
        confirm_disable_admin_two_factor: "DISABLE"
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(BookingConfiguration.current.admin_two_factor_mode).to eq("optional")
    end
  end

  it "redirects enrollment start to the enrollment panel anchor" do
    post enroll_admin_security_path

    expect(response).to redirect_to("#{admin_security_path}#admin-security-enrollment-panel")
  end

  it "renders enrollment with scroll behavior after an invalid OTP attempt" do
    post enroll_admin_security_path

    patch confirm_admin_security_path, params: { admin: { otp_attempt: "000000" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('id="admin-security-enrollment-panel"')
    expect(response.body).to include("data-scroll-into-view-on-load")
  end
end
