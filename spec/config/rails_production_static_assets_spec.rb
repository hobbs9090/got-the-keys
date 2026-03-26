require "rails_helper"
require "bundler"
require "json"
require "open3"
require "rbconfig"

RSpec.describe "Rails production static asset serving" do
  RESULT_PREFIX = "__RESULT__".freeze

  def rails_production_config(env = {})
    runner = <<~RUBY
      require "json"

      payload = {
        enabled: Rails.application.config.public_file_server.enabled,
        middleware: Rails.application.middleware.map(&:klass).map(&:to_s).grep(/AssetPublicFileServer|ActionDispatch::Static/)
      }

      puts "#{RESULT_PREFIX}\#{payload.to_json}"
    RUBY

    stdout = stderr = status = nil

    Bundler.with_unbundled_env do
      stdout, stderr, status = Open3.capture3(
        {
          "SECRET_KEY_BASE" => "dummy",
          "RAILS_ENV" => "production"
        }.merge(env),
        RbConfig.ruby,
        "-S",
        "bundle",
        "exec",
        "rails",
        "runner",
        runner,
        chdir: Rails.root.to_s
      )
    end

    expect(status.success?).to be(true), <<~MESSAGE
      expected Rails production runner to succeed
      stdout:
      #{stdout}

      stderr:
      #{stderr}
    MESSAGE

    result_line = stdout.each_line.find { |line| line.start_with?(RESULT_PREFIX) }
    expect(result_line).to be_present, "expected runner output to include #{RESULT_PREFIX.inspect}, got:\n#{stdout}"

    JSON.parse(result_line.delete_prefix(RESULT_PREFIX))
  end

  it "does not add static asset middleware when Rails is not serving static files" do
    config = rails_production_config

    expect(config["enabled"]).to eq(false)
    expect(config["middleware"]).to eq([])
  end

  it "inserts the asset cache middleware ahead of ActionDispatch::Static when enabled" do
    config = rails_production_config("RAILS_SERVE_STATIC_FILES" => "1")

    expect(config["enabled"]).to eq(true)
    expect(config["middleware"]).to eq(["AssetPublicFileServer", "ActionDispatch::Static"])
  end
end
