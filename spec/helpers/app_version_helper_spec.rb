require "rails_helper"

RSpec.describe AppVersionHelper, type: :helper do
  let(:version_config) { Rails.configuration.x.got_the_keys }

  around do |example|
    original_values = {
      version: version_config.version,
      build_sha: version_config.build_sha,
      local_build: version_config.local_build,
      build_number: version_config.build_number,
      deployed_at: version_config.deployed_at,
      deploy_target: version_config.deploy_target
    }

    example.run
  ensure
    version_config.version = original_values[:version]
    version_config.build_sha = original_values[:build_sha]
    version_config.local_build = original_values[:local_build]
    version_config.build_number = original_values[:build_number]
    version_config.deployed_at = original_values[:deployed_at]
    version_config.deploy_target = original_values[:deploy_target]
  end

  it "formats the public app version from the semantic version" do
    version_config.version = "2.4.0"

    expect(helper.public_app_version).to eq("v2.4.0")
  end

  it "exposes the git sha and build number separately" do
    version_config.build_sha = "abc1234"
    version_config.build_number = "42"

    expect(helper.app_build_sha).to eq("abc1234")
    expect(helper.short_app_build_sha).to eq("abc1234")
    expect(helper.app_build_number).to eq("42")
  end

  it "uses the live git sha on localhost development renders" do
    version_config.build_sha = "stale123"
    version_config.build_number = nil

    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    allow(ReleaseBuildMetadata).to receive(:current_revision).with(Rails.root).and_return("fresh456")

    expect(helper.app_build_sha).to eq("fresh456")
    expect(helper.short_app_build_sha).to eq("fresh45")
  end

  it "uses the live workspace dirty state on localhost development renders" do
    version_config.local_build = false
    version_config.build_number = nil

    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
    allow(ReleaseBuildMetadata).to receive(:workspace_dirty?).with(Rails.root).and_return(true)

    expect(helper.local_app_build?).to be(true)
  end

  it "keeps configured build metadata outside localhost development" do
    version_config.build_sha = "abc1234"
    version_config.local_build = false
    version_config.build_number = "42"

    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))

    expect(ReleaseBuildMetadata).not_to receive(:current_revision)
    expect(ReleaseBuildMetadata).not_to receive(:workspace_dirty?)

    expect(helper.app_build_sha).to eq("abc1234")
    expect(helper.local_app_build?).to be(false)
  end

  it "truncates longer build shas for compact UI displays" do
    version_config.build_sha = "abc1234def5678"

    expect(helper.short_app_build_sha).to eq("abc1234")
  end

  it "appends a local suffix when the running build includes uncommitted changes" do
    version_config.build_sha = "abc1234def5678"
    version_config.local_build = true

    expect(helper.display_app_build_sha).to eq("abc1234 + local")
  end

  it "returns the short build sha unchanged for clean builds" do
    version_config.build_sha = "abc1234def5678"
    version_config.local_build = false

    expect(helper.display_app_build_sha).to eq("abc1234")
  end

  it "falls back cleanly when build metadata is missing" do
    expect(helper.app_build_value(nil)).to eq("Not available")
  end

  it "formats the deployed timestamp for display" do
    version_config.deployed_at = "2026-03-26T09:00:00Z"

    timestamp = Time.zone.parse("2026-03-26T09:00:00Z")
    expect(helper.app_deployed_at).to eq("#{I18n.l(timestamp, format: :long)} #{timestamp.zone}")
  end

  it "returns the raw deployed value when it cannot be parsed as a timestamp" do
    version_config.deployed_at = "build just finished"

    expect(helper.app_deployed_at).to eq("build just finished")
  end

  it "combines the deploy target and Rails environment for diagnostics" do
    version_config.deploy_target = "staging host"

    expect(helper.app_runtime_environment).to eq("staging host, Rails env test")
  end

  it "still reports the Rails environment when no deploy target is set" do
    version_config.deploy_target = nil

    expect(helper.app_runtime_environment).to eq("Rails env test")
  end

  it "includes build metadata in the full app version when present" do
    version_config.version = "2.4.0"
    version_config.build_sha = "abc1234"
    version_config.build_number = "42"

    expect(helper.full_app_version).to eq("v2.4.0+abc1234.42")
  end

  it "omits blank build metadata cleanly" do
    version_config.version = "2.4.0"
    version_config.build_sha = nil
    version_config.build_number = ""

    expect(helper.full_app_version).to eq("v2.4.0")
  end
end
