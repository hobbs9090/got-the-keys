require_relative "production"

GotTheKeys::Application.configure do
  config.x.got_the_keys.public_indexing_enabled = false
  config.log_tags = [:request_id, ->(_request) { "staging" }]
end
