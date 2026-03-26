return unless ENV["ALLURE_REPORTS"] == "1"

require "allure-rspec"

AllureRspec.configure do |config|
  config.results_directory = ENV.fetch("ALLURE_RESULTS_DIR", Rails.root.join("tmp/allure-results").to_s)
  config.clean_results_directory = ENV["ALLURE_CLEAN_RESULTS"] == "1"
  config.environment_properties = {
    ci: ENV.fetch("CI", "false"),
    rails_version: Rails.version,
    ruby_engine: RUBY_ENGINE,
    ruby_version: RUBY_VERSION,
    rspec_version: RSpec::Core::Version::STRING,
    os_platform: RbConfig::CONFIG["host_os"]
  }
end
