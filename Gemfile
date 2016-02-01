source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'

gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'compass-rails', '~> 2.0.5'
gem 'zurb-foundation'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

# Use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

# Use Devise for Authentication
gem 'devise'
gem 'protected_attributes'

# Pagination
gem 'kaminari'

# Performance Testing
gem 'rails-perftest'
gem 'ruby-prof'

# Use Capistrano for deployment
gem 'capistrano-rvm'
gem 'capistrano-rails'
gem 'capistrano-passenger'

# Charts

# Alternative to connecting to SMTP server for devise 'confirmable' registrations
gem 'letter_opener'

# Performance profiler
#gem 'rack-mini-profiler'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'populator'
  gem 'faker'
end

group :test do
  gem 'cucumber-rails', :require => false
  # TODO downgraded to 'database_cleaner', '< 1.1.0' after issue - NameError: undefined local variable or method `postgresql_version'
  gem 'database_cleaner', '< 1.1.0'
  gem 'capybara'
end

group :production do
  gem 'pg'
end