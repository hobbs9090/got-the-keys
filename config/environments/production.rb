require Rails.root.join("lib/asset_public_file_server")

GotTheKeys::Application.configure do
  serve_static_files = ENV["RAILS_SERVE_STATIC_FILES"].present?

  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.enabled = serve_static_files
  config.middleware.insert_before(ActionDispatch::Static, AssetPublicFileServer, Rails.root.join("public").to_s) if serve_static_files
  config.assume_ssl = true if ENV['ASSUME_SSL'].present?
  config.assets.compile = false
  config.force_ssl = ENV['FORCE_SSL'].present?
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL', 'info')
  config.log_tags = [:request_id]
  config.cache_store = :memory_store
  config.action_mailer.perform_caching = false
  config.active_job.queue_adapter = (config.x.got_the_keys.active_job_queue_adapter || "async").to_sym
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = {
    host: ENV.fetch('APP_HOST', 'localhost'),
    protocol: 'https'
  }
  if ENV['SMTP_ADDRESS'].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch('SMTP_ADDRESS'),
      port: Integer(ENV.fetch('SMTP_PORT', 587)),
      domain: ENV.fetch('SMTP_DOMAIN', ENV.fetch('APP_HOST', 'localhost')),
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: ENV.fetch('SMTP_AUTHENTICATION', 'plain').to_sym,
      enable_starttls_auto: ENV.fetch('SMTP_STARTTLS_AUTO', 'true') == 'true'
    }.compact
  else
    config.action_mailer.delivery_method = :file
    config.action_mailer.file_settings = { location: Rails.root.join('tmp', 'mails') }
  end
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.log_formatter = ::Logger::Formatter.new
  config.logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
  config.active_record.dump_schema_after_migration = false
end
