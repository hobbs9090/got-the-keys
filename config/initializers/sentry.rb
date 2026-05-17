Sentry.init do |config|
  sentry_release = ENV["SENTRY_RELEASE"].presence

  unless sentry_release
    sentry_release = "got-the-keys@#{Rails.configuration.x.got_the_keys.version}"
    sentry_release = "#{sentry_release}+#{Rails.configuration.x.got_the_keys.build_sha}" if Rails.configuration.x.got_the_keys.build_sha.present?
  end

  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.enabled_environments = %w[staging production]
  config.environment = ENV["SENTRY_ENVIRONMENT"].presence || Rails.configuration.x.got_the_keys.deploy_target.presence || Rails.env
  config.release = sentry_release

  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.05").to_f
  config.send_default_pii = true
end
