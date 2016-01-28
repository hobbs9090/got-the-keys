require 'watir-webdriver'

Before do
  @browser = Watir::Browser.new :firefox
end

After do
  timestamp = "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
  encoded_img = @browser.driver.screenshot_as(:base64)
  embed("data:image/png;base64,#{encoded_img}", 'image/png', "#{timestamp}")
  @browser.close unless @browser.nil?
end

at_exit do
  @browser.close unless @browser.nil?
end