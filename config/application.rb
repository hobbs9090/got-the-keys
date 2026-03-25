require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups) if defined?(Bundler)

module GotTheKeys
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.default_locale = :en
    config.filter_parameters += %i[password password_confirmation]
    config.x.got_the_keys.available_languages = %w[en zh].freeze
    config.x.got_the_keys.exchange_rate_gbp_to_cny = 9.368

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
      g.view_specs false
      g.helper_specs false
    end
  end
end
