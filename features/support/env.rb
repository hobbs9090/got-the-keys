require "database_cleaner/active_record"
require "cucumber/rails"

DatabaseCleaner.strategy = :transaction
Cucumber::Rails::Database.javascript_strategy = :truncation
