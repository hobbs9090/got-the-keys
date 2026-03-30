require_relative "production"

GotTheKeys::Application.configure do
  config.log_tags = [:request_id, ->(_request) { "staging" }]
end
