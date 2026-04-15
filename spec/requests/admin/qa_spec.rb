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
    expect(response.body).to include("favicon.ico")

    document = Nokogiri::HTML.parse(response.body)
    top_section = document.at_css(".admin-section")
    section_heading = top_section.at_css(".section-heading")
    version_box = document.at_css(%([data-testid="qa-version-box"]))

    expect(top_section.element_children.index(section_heading)).to be < top_section.element_children.index(version_box)
    expect(section_heading.at_css("h1").text.strip).to eq(I18n.t("ui.admin.qa.title"))
    expect(version_box).to be_present
    expect(version_box.at_css(%([data-testid="qa-app-version"])).text).to eq("v2.4.0+abc1234.42")
    expect(version_box.at_css(%([data-testid="qa-git-sha"])).text).to eq("abc1234")
    expect(version_box.at_css(%([data-testid="qa-build-number"])).text).to eq("42")
    timestamp = Time.zone.parse("2026-03-26T09:00:00Z")
    expect(version_box.at_css(%([data-testid="qa-deployed-at"])).text).to eq("#{I18n.l(timestamp, format: :long)} #{timestamp.zone}")
    expect(version_box.at_css(%([data-testid="qa-environment"])).text).to eq("staging host, Rails env test")
  end

  it "shows runtime diagnostics and selector contracts" do
    DemoData::ScenarioLoader.new.apply_catalog!(key: "baseline", actor_email: admin.email)

    get admin_qa_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("mail delivery mode".humanize)
    expect(response.body).to include(ActionMailer::Base.delivery_method.to_s)
    expect(response.body).to include("property-card")
    expect(response.body).not_to include("Scenario families")
    expect(response.body).not_to include("Happy path")
    expect(response.body).not_to include("Known credentials")
    expect(response.body).not_to include(%(data-testid="qa-credentials"))
  end

  it "keeps the admin 2FA mode controls off the QA guide" do
    get admin_qa_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(%(data-testid="admin-two-factor-mode-panel"))
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
