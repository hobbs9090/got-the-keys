if defined?(Selenium::WebDriver)
  Selenium::WebDriver.logger.level = :error
end

RSpec.configure do |config|
  config.before(type: :system) do
    driven_by(:rack_test)
  end

  config.before(type: :system, js: true) do
    driven_by(:selenium, using: :headless_firefox, screen_size: [1440, 1200])
  end
end
