require "json"
require "time"
require "stringio"
require_relative "../lib/release_build_metadata"

# config valid only for current version of Capistrano
lock '3.20.0'

# Application config
set :application, 'got_the_keys'
set :repo_url, ENV.fetch('DEPLOY_REPO_URL', 'git@github.com:hobbs9090/rails_got_the_keys.git')
set :branch, ENV.fetch('DEPLOY_BRANCH', 'master')
set :ssh_options, forward_agent: true

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/got_the_keys'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Persist writable and generated paths across releases.
append :linked_dirs,
       'log',
       'tmp/pids',
       'tmp/cache',
       'tmp/sockets',
       'storage',
       'vendor/bundle',
       'node_modules'

set :passenger_in_gemfile, true
set :passenger_restart_with_touch, true
set :bundle_without, %w[development test].join(' ')

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

namespace :deploy do
  desc "Writes deploy build metadata for runtime diagnostics"
  task :write_build_metadata do
    on roles(:app) do
      build_info_path = shared_path.join("storage", "build_info.json")
      execute :mkdir, "-p", shared_path.join("storage")
      previous_metadata = begin
        test("[ -f #{build_info_path} ]") ? JSON.parse(capture(:cat, build_info_path)) : {}
      rescue JSON::ParserError
        {}
      end
      build_metadata = ReleaseBuildMetadata.payload(
        previous_metadata: previous_metadata,
        current_revision: fetch(:current_revision),
        requested_build_sha: ENV["APP_BUILD_SHA"],
        requested_build_number: ENV["APP_BUILD_NUMBER"],
        deployed_at: Time.now.utc.iso8601
      )

      upload! StringIO.new(JSON.pretty_generate(build_metadata)), build_info_path
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

before "passenger:restart", "deploy:write_build_metadata"
