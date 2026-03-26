require "rails_helper"

RSpec.describe AppVersionHelper, type: :helper do
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

  it "formats the public app version from the semantic version" do
    version_config.version = "2.4.0"

    expect(helper.public_app_version).to eq("v2.4.0")
  end

  it "exposes the git sha and build number separately" do
    version_config.build_sha = "abc1234"
    version_config.build_number = "42"

    expect(helper.app_build_sha).to eq("abc1234")
    expect(helper.app_build_number).to eq("42")
  end

  it "falls back cleanly when build metadata is missing" do
    expect(helper.app_build_value(nil)).to eq("Not available")
  end

  it "formats the deployed timestamp for display" do
    version_config.deployed_at = "2026-03-26T09:00:00Z"

    expect(helper.app_deployed_at).to eq(I18n.l(Time.zone.parse("2026-03-26T09:00:00Z"), format: :long))
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
