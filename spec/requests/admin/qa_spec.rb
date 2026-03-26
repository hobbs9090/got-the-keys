require "rails_helper"

RSpec.describe "Admin QA guide" do
  let(:admin) { FactoryBot.create(:admin, email: "qa-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme") }
  let(:version_config) { Rails.configuration.x.got_the_keys }

  around do |example|
    original_values = {
      version: version_config.version,
      build_sha: version_config.build_sha,
      build_number: version_config.build_number
    }

    example.run
  ensure
    version_config.version = original_values[:version]
    version_config.build_sha = original_values[:build_sha]
    version_config.build_number = original_values[:build_number]
  end

  before do
    sign_in admin
  end

  it "shows the version number and git details in the release box" do
    version_config.version = "2.4.0"
    version_config.build_sha = "abc1234"
    version_config.build_number = "42"

    get admin_qa_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to match(%r{favicon-house-[^"]+\.svg})
    expect(response.body).not_to include("favicon.ico")

    document = Nokogiri::HTML.parse(response.body)
    version_box = document.at_css(%([data-testid="qa-version-box"]))

    expect(version_box).to be_present
    expect(version_box.at_css(%([data-testid="qa-app-version"])).text).to eq("v2.4.0")
    expect(version_box.at_css(%([data-testid="qa-git-sha"])).text).to eq("abc1234")
    expect(version_box.at_css(%([data-testid="qa-build-number"])).text).to eq("42")
  end

  it "places the QA guide link at the bottom of the admin workspace navigation" do
    get admin_root_path

    expect(response).to have_http_status(:ok)

    navigation_testids = Nokogiri::HTML.parse(response.body)
      .css(".admin-nav__menu [data-testid]")
      .map { |node| node["data-testid"] }

    expect(navigation_testids.last).to eq("admin-qa-link")
    expect(navigation_testids).to include("admin-booking-rules-link")
  end
end
