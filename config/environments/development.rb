require 'active_support/core_ext/integer/time'

GotTheKeys::Application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  config.active_job.queue_adapter = (config.x.got_the_keys.active_job_queue_adapter || "async").to_sym
  config.x.got_the_keys.public_indexing_enabled = false

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.action_view.annotate_rendered_view_with_filenames = true
  config.assets.resolve_with = [:environment]
  config.public_file_server.headers = { 'Cache-Control' => 'no-store' }
  config.assets.quiet = true
end
