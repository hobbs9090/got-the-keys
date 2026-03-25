require "rails_helper"

RSpec.describe AppVersionHelper, type: :helper do
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

  it "formats the public app version from the semantic version" do
    version_config.version = "2.4.0"

    expect(helper.public_app_version).to eq("v2.4.0")
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
