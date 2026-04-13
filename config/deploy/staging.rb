version_env = {
  "APP_VERSION" => ENV["APP_VERSION"],
  "APP_BUILD_SHA" => ENV["APP_BUILD_SHA"],
  "APP_BUILD_NUMBER" => ENV["APP_BUILD_NUMBER"]
}.reject { |_key, value| value.nil? || value.empty? }

runtime_env = {
  "DATABASE_URL" => ENV["DATABASE_URL"],
  "DATABASE_NAME" => ENV.fetch("DATABASE_NAME", "gotthekeys_staging"),
  "DATABASE_HOST" => ENV["DATABASE_HOST"],
  "DATABASE_PORT" => ENV["DATABASE_PORT"],
  "DATABASE_USERNAME" => ENV["DATABASE_USERNAME"],
  "DATABASE_PASSWORD" => ENV["DATABASE_PASSWORD"]
}.reject { |_key, value| value.nil? || value.empty? }

server ENV.fetch("DEPLOY_HOST", "192.168.2.204"),
       user: ENV.fetch("DEPLOY_USER", ENV.fetch("USER", "deploy")),
       roles: %w[app db web]

set :deploy_to, ENV.fetch("DEPLOY_TO", "/var/www/gotthekeys-staging")
set :rails_env, "staging"
set :reset_db_on_deploy, true
set :bundle_without, %w[development test doc production].join(' ')
set :default_env, {
  "PATH" => "$HOME/.local/bin:$HOME/.rbenv/bin:$HOME/.rbenv/shims:/usr/local/bin:/usr/bin:/bin",
  "APP_HOST" => ENV.fetch("APP_HOST", "stevenhobbs.co.uk"),
  "APP_DEPLOY_TARGET" => ENV.fetch("APP_DEPLOY_TARGET", "staging host"),
  "RAILS_SERVE_STATIC_FILES" => "1",
  "SECRET_KEY_BASE_DUMMY" => "1"
}.merge(version_env).merge(runtime_env)
