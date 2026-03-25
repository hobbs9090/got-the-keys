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

  it "shows the full app version in diagnostics" do
    version_config.version = "2.4.0"
    version_config.build_sha = "abc1234"
    version_config.build_number = "42"

    get admin_qa_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(data-testid="qa-app-version"))
    expect(response.body).to include("v2.4.0+abc1234.42")
  end
end
