GotTheKeys::Application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assume_ssl = true if ENV['ASSUME_SSL'].present?
  config.assets.compile = false
  config.force_ssl = ENV['FORCE_SSL'].present?
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')
  config.log_tags = [:request_id]
  config.cache_store = :memory_store
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = {
    host: ENV.fetch('APP_HOST', 'localhost'),
    protocol: 'https'
  }
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.log_formatter = ::Logger::Formatter.new
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
  config.active_record.dump_schema_after_migration = false
end
