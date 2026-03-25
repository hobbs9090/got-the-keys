source 'https://rubygems.org'

ruby '3.4.7'

# Rails 7.x
gem 'rails', '~> 7.1.0'

# Use sqlite3 as the database for Active Record (development/test)
gem 'sqlite3', '~> 1.4'
gem 'puma'

gem 'sassc-rails'
# coffee-rails is obsolete in Rails 7; use JS bundling instead
# gem 'coffee-rails'
# Uglifier not required when using jsbundling
# gem 'uglifier'
# Legacy feature toggle; can re-add with modern style use if needed
# gem 'compass-rails', '~> 2.0.5'
# gem 'zurb-foundation'

# Use jquery as the JavaScript library
gem 'jquery-rails', '~> 4.6'

# Rails 7 uses Turbo and Stimulus for accelerated UI
gem 'turbo-rails'
gem 'stimulus-rails'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.14'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
# bcrypt-ruby is deprecated, use bcrypt for Ruby 3.x
gem 'bcrypt', '~> 3.1.18'

# Build HTML/XML parsing for tests and Rails internals.
gem 'nokogiri', '~> 1.16'

# Use unicorn as the app server
# gem 'unicorn'

# Use debugger
# gem 'debugger', group: [:development, :test]

# Use Devise for Authentication
gem 'devise'
# protected_attributes is not Rails 7-compatible; use strong params instead
# gem 'protected_attributes'

# Pagination
gem 'kaminari', '~> 1.2'

# Performance Testing
# old ruby-prof used by Rails 4; optional in Rails 7 with newer profiling tools
gem 'ruby-prof', '~> 1.4', require: false

# Use Capistrano for deployment
gem 'capistrano'
gem 'capistrano-rails'
gem 'capistrano-passenger'

# Charts

# Alternative to connecting to SMTP server for devise 'confirmable' registrations
gem 'letter_opener'

# Performance profiler
#gem 'rack-mini-profiler'

group :development, :test do
  gem 'rspec-rails', '~> 6.1'
  gem 'factory_bot_rails', '~> 6.5'
  gem 'observer'
  gem 'populator'
  gem 'faker'
end

group :test do
  gem 'cucumber-rails', '~> 4.0', require: false
  gem 'database_cleaner-active_record', '~> 2.1'
  gem 'capybara', '~> 3.40'
  gem 'rake', '~> 13.0'
end

group :production do
  #gem 'pg' removed and replaced with SQlite until issues with pg fixed.
  gem 'passenger'
end
