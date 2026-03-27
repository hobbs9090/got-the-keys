require "rails_helper"

RSpec.describe "Admin QA guide" do
  let(:admin) { FactoryBot.create(:admin, email: "qa-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }
  let(:version_config) { Rails.configuration.x.got_the_keys }

  around do |example|
    original_values = {
      version: version_config.version,
      build_sha: version_config.build_sha,
      build_number: version_config.build_number,
      deployed_at: version_config.deployed_at,
      deploy_target: version_config.deploy_target
    }

    example.run
  ensure
    version_config.version = original_values[:version]
    version_config.build_sha = original_values[:build_sha]
    version_config.build_number = original_values[:build_number]
    version_config.deployed_at = original_values[:deployed_at]
    version_config.deploy_target = original_values[:deploy_target]
  end

  before do
    sign_in admin
  end

  it "shows the version number and git details in the release box" do
    version_config.version = "2.4.0"
    version_config.build_sha = "abc1234"
    version_config.build_number = "42"
    version_config.deployed_at = "2026-03-26T09:00:00Z"
    version_config.deploy_target = "staging host"

    get admin_qa_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to match(%r{favicon-house-[^"]+\.svg})
    expect(response.body).not_to include("favicon.ico")

    document = Nokogiri::HTML.parse(response.body)
    version_box = document.at_css(%([data-testid="qa-version-box"]))

    expect(version_box).to be_present
    expect(version_box.at_css(%([data-testid="qa-app-version"])).text).to eq("v2.4.0+abc1234.42")
    expect(version_box.at_css(%([data-testid="qa-git-sha"])).text).to eq("abc1234")
    expect(version_box.at_css(%([data-testid="qa-build-number"])).text).to eq("42")
    expect(version_box.at_css(%([data-testid="qa-deployed-at"])).text).to eq(I18n.l(Time.zone.parse("2026-03-26T09:00:00Z"), format: :long))
    expect(version_box.at_css(%([data-testid="qa-environment"])).text).to eq("staging host, Rails env test")
  end

  it "shows runtime diagnostics, seeded personas, and selector contracts" do
    DemoData::ScenarioLoader.new.apply_catalog!(key: "baseline", actor_email: admin.email)

    get admin_qa_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("mail delivery mode".humanize)
    expect(response.body).to include(ActionMailer::Base.delivery_method.to_s)
    expect(response.body).to include("seeded personas".humanize)
    expect(response.body).to include("Admins:")
    expect(response.body).to include("property-card")
    expect(response.body).to include("Scenario families")
    expect(response.body).to include("Happy path")
  end

  it "shows the admin 2FA mode panel and dedicated security page link" do
    get admin_qa_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Admin 2FA mode")
    expect(response.body).to include(admin_security_path)
    expect(response.body).to include("Current mode")
    expect(response.body).to include("Disabled")
  end

  it "updates the admin 2FA mode to optional and audits the change" do
    patch admin_qa_path, params: { booking_configuration: { admin_two_factor_mode: "optional" } }

    expect(response).to redirect_to(admin_qa_path)
    expect(BookingConfiguration.current.admin_two_factor_mode).to eq("optional")

    audit_log = AuditLog.recent_first.find_by(action: "admin_two_factor_mode_changed")
    expect(audit_log).to be_present
    expect(audit_log.admin).to eq(admin)
    expect(audit_log.metadata).to include("from" => "disabled", "to" => "optional")
  end

  it "requires explicit confirmation before switching admin 2FA to disabled" do
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    patch admin_qa_path, params: { booking_configuration: { admin_two_factor_mode: "disabled" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Type DISABLE to confirm switching the global admin 2FA mode to disabled.")
    expect(BookingConfiguration.current.admin_two_factor_mode).to eq("optional")
  end

  it "switches admin 2FA back to disabled when the confirmation phrase is supplied" do
    BookingConfiguration.current.update!(admin_two_factor_mode: "optional")

    patch admin_qa_path, params: {
      booking_configuration: { admin_two_factor_mode: "disabled" },
      confirm_disable_admin_two_factor: "DISABLE"
    }

    expect(response).to redirect_to(admin_qa_path)
    expect(BookingConfiguration.current.admin_two_factor_mode).to eq("disabled")

    audit_log = AuditLog.recent_first.find_by(action: "admin_two_factor_mode_changed")
    expect(audit_log.metadata).to include("from" => "optional", "to" => "disabled")
  end

  it "places the QA guide link at the bottom of the admin workspace navigation" do
    get admin_root_path

    expect(response).to have_http_status(:ok)

    navigation_testids = Nokogiri::HTML.parse(response.body)
      .css(".admin-nav__menu [data-testid]")
      .map { |node| node["data-testid"] }

    expect(navigation_testids.last).to eq("admin-qa-link")
    expect(navigation_testids).to include("admin-booking-rules-link")
    expect(navigation_testids).to include("admin-security-link")
  end
end
