require "rails_helper"

RSpec.describe "Admin security" do
  let(:admin) { FactoryBot.create(:admin, email: "security-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }

  before do
    sign_in admin
  end

  it "shows the admin 2FA mode card on the security page" do
    get admin_security_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Admin 2FA mode")
    expect(response.body).to include("Current mode")
    expect(response.body).to include("Disabled")
    expect(response.body).to include(%(data-testid="admin-two-factor-mode-panel"))
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
end
