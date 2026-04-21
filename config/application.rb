require_relative 'boot'
require_relative '../lib/release_build_metadata'
require_relative '../lib/passenger_set_cookie_compatibility'
require_relative '../lib/strip_passenger_headers'

require 'rails/all'
require 'json'

Bundler.require(*Rails.groups) if defined?(Bundler)

module GotTheKeys
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    version_path = root.join("VERSION")
    build_info_path = root.join("storage", "build_info.json")
    semantic_version = ENV["APP_VERSION"].presence || version_path.read.strip.presence
    build_metadata = ReleaseBuildMetadata.load(build_info_path)
    current_revision = ReleaseBuildMetadata.current_revision(root)
    using_runtime_git_revision = ENV["APP_BUILD_SHA"].blank? && build_metadata["build_sha"].blank? && current_revision.present?
    raise "VERSION file must contain a semantic version" if semantic_version.blank?

    config.i18n.available_locales = %i[en zh de fr it]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = {
      zh: :en,
      de: :en,
      fr: :en,
      it: :en
    }
    config.filter_parameters += %i[password password_confirmation otp_attempt]
    config.x.got_the_keys.available_languages = %w[en de fr it zh].freeze
    app_time_zone = ENV.fetch("APP_TIME_ZONE", "Europe/London")
    raise "APP_TIME_ZONE must be a valid ActiveSupport time zone" unless ActiveSupport::TimeZone[app_time_zone]

    config.time_zone = app_time_zone
    config.x.got_the_keys.time_zone = app_time_zone
    config.x.got_the_keys.exchange_rate_gbp_to_cny = 9.368
    config.x.got_the_keys.version = semantic_version
    config.x.got_the_keys.build_sha = ENV["APP_BUILD_SHA"].presence || build_metadata["build_sha"].presence || current_revision
    config.x.got_the_keys.local_build = using_runtime_git_revision && ReleaseBuildMetadata.workspace_dirty?(root)
    config.x.got_the_keys.build_number = ENV["APP_BUILD_NUMBER"].presence || build_metadata["build_number"].presence
    config.x.got_the_keys.deployed_at = build_metadata["deployed_at"].presence
    config.x.got_the_keys.deploy_target = ENV["APP_DEPLOY_TARGET"].presence
    config.x.got_the_keys.active_job_queue_adapter = ENV["ACTIVE_JOB_QUEUE_ADAPTER"].presence
    config.x.got_the_keys.public_indexing_enabled = false
    config.middleware.insert_before ActionDispatch::Cookies, PassengerSetCookieCompatibility
    config.middleware.use StripPassengerHeaders
    config.middleware.use Rack::Attack

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.view_specs false
      g.helper_specs false
    end
  end
end
