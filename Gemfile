source 'https://rubygems.org'

ruby '3.4.7'

gem 'rails', '~> 8.1.3'
gem 'sqlite3', '~> 2.1'
gem 'puma', '~> 7.2'
gem 'bootsnap', require: false
gem 'sprockets-rails'
gem 'cssbundling-rails'
gem 'jsbundling-rails'
gem 'turbo-rails'
gem 'jbuilder', '~> 2.14'
gem 'devise', '~> 5.0'
gem 'devise-two-factor', '~> 6.4'
gem 'kaminari', '~> 1.2'
gem 'openai', '~> 0.56.0'
gem 'rqrcode', '~> 3.0'

group :doc do
  gem 'sdoc', require: false
end

gem 'bcrypt', '~> 3.1.18'
gem 'nokogiri', '~> 1.16'

group :development, :test do
  gem 'rspec-rails', '~> 8.0'
  gem 'factory_bot_rails', '~> 6.5'
  gem 'faker', '~> 3.6'
end

group :development do
  gem 'capistrano', '~> 3.20'
  gem 'capistrano-passenger', '~> 0.2.1'
  gem 'capistrano-rails', '~> 1.7'
  gem 'bcrypt_pbkdf', '~> 1.1'
  gem 'ed25519', '~> 1.3'
  gem 'letter_opener', '~> 1.10'
  gem 'ruby-lsp', require: false
  gem 'ruby-lsp-rails', require: false
end

group :test do
  gem 'allure-rspec', '~> 2.28'
  gem 'capybara', '~> 3.40'
  gem 'rake', '~> 13.0'
  gem 'selenium-webdriver', '~> 4.0'
end

group :production do
  gem 'passenger', '~> 6.1'
end
