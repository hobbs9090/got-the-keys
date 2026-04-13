require "rails_helper"
require "nokogiri"

RSpec.describe "Admin security" do
  let(:admin) { FactoryBot.create(:admin, email: "security-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  def parsed_html
    Nokogiri::HTML.parse(response.body)
  end

  it "shows the admin 2FA mode card on the security page" do
    get admin_security_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Admin 2FA mode")
    expect(response.body).to include(%(data-testid="admin-two-factor-mode-controls"))
    expect(response.body).to include(%(id="disable-admin-two-factor-mode-modal"))
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
    expect(response.body).to include("Type DISABLE to confirm switching the global admin 2FA mode to disabled.")
    expect(BookingConfiguration.current.admin_two_factor_mode).to eq("optional")
  end

  it "renders the disable confirmation modal trigger when the mode is optional" do
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    get admin_security_path

    trigger = parsed_html.at_css('[data-modal-trigger="disable-admin-two-factor-mode-modal"]')
    expect(trigger).to be_present
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
