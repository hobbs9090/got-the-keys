GotTheKeys::Application.configure do
  config.enable_reloading = false
  config.eager_load = ENV['CI'].present?
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.action_dispatch.show_exceptions = :none
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: 'www.example.com' }
  config.active_job.queue_adapter = (config.x.got_the_keys.active_job_queue_adapter || "test").to_sym
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  if config.respond_to?(:assets)
    config.assets.resolve_with = [:environment]
    config.assets.check_precompiled_asset = false
  end
end
