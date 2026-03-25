require_relative 'boot'

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
    build_metadata = build_info_path.exist? ? JSON.parse(build_info_path.read) : {}
    raise "VERSION file must contain a semantic version" if semantic_version.blank?

    config.i18n.default_locale = :en
    config.i18n.fallbacks = { zh: :en }
    config.filter_parameters += %i[password password_confirmation]
    config.x.got_the_keys.available_languages = %w[en zh].freeze
    config.x.got_the_keys.exchange_rate_gbp_to_cny = 9.368
    config.x.got_the_keys.version = semantic_version
    config.x.got_the_keys.build_sha = ENV["APP_BUILD_SHA"].presence || build_metadata["build_sha"].presence
    config.x.got_the_keys.build_number = ENV["APP_BUILD_NUMBER"].presence || build_metadata["build_number"].presence

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.view_specs false
      g.helper_specs false
    end
  end
end
