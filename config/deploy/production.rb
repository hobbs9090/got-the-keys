version_env = {
  "APP_VERSION" => ENV["APP_VERSION"],
  "APP_BUILD_SHA" => ENV["APP_BUILD_SHA"],
  "APP_BUILD_NUMBER" => ENV["APP_BUILD_NUMBER"]
}.reject { |_key, value| value.nil? || value.empty? }

runtime_env = {
  "FORCE_SSL" => ENV["FORCE_SSL"],
  "ASSUME_SSL" => ENV["ASSUME_SSL"],
  "RAILS_LOG_LEVEL" => ENV["RAILS_LOG_LEVEL"],
  "ACTIVE_JOB_QUEUE_ADAPTER" => ENV["ACTIVE_JOB_QUEUE_ADAPTER"],
  "DEVISE_SECRET_KEY" => ENV["DEVISE_SECRET_KEY"],
  "DATABASE_URL" => ENV["DATABASE_URL"],
  "DATABASE_NAME" => ENV.fetch("DATABASE_NAME", "gotthekeys_production"),
  "DATABASE_HOST" => ENV["DATABASE_HOST"],
  "DATABASE_PORT" => ENV["DATABASE_PORT"],
  "DATABASE_USERNAME" => ENV["DATABASE_USERNAME"],
  "DATABASE_PASSWORD" => ENV["DATABASE_PASSWORD"],
  "SMTP_ADDRESS" => ENV["SMTP_ADDRESS"],
  "SMTP_PORT" => ENV["SMTP_PORT"],
  "SMTP_DOMAIN" => ENV["SMTP_DOMAIN"],
  "SMTP_USERNAME" => ENV["SMTP_USERNAME"],
  "SMTP_PASSWORD" => ENV["SMTP_PASSWORD"],
  "SMTP_AUTHENTICATION" => ENV["SMTP_AUTHENTICATION"],
  "SMTP_STARTTLS_AUTO" => ENV["SMTP_STARTTLS_AUTO"]
}.reject { |_key, value| value.nil? || value.empty? }

server ENV.fetch("DEPLOY_HOST"),
       user: ENV.fetch("DEPLOY_USER", "deploy"),
       roles: %w[app db web]

set :deploy_to, ENV.fetch("DEPLOY_TO")
set :rails_env, "production"
set :bundle_without, %w[development test doc staging].join(" ")
set :default_env, {
  "PATH" => "$HOME/.local/bin:$HOME/.rbenv/bin:$HOME/.rbenv/shims:/usr/local/bin:/usr/bin:/bin",
  "APP_HOST" => ENV.fetch("APP_HOST", "gotthekeys.uk"),
  "APP_DEPLOY_TARGET" => ENV.fetch("APP_DEPLOY_TARGET", "production host"),
  "RAILS_SERVE_STATIC_FILES" => "1",
  "SECRET_KEY_BASE_DUMMY" => "1"
}.merge(version_env).merge(runtime_env)
