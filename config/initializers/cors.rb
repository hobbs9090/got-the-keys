# CORS for the JSON API. The iOS app makes native HTTPS requests so CORS is a
# no-op for it — these rules exist for future SPAs and curl/Charles debugging.
#
# Origins are configured via CORS_API_ORIGINS, a comma-separated allow-list.
# Default is "*" in development for convenience and "https://gotthekeys.example"
# (placeholder) in production — override per environment.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  origins_string = ENV.fetch("CORS_API_ORIGINS") do
    Rails.env.development? ? "*" : "https://gotthekeys.example"
  end
  api_origins = origins_string.split(",").map(&:strip).reject(&:empty?)

  allow do
    origins(*api_origins)

    resource "/api/*",
             headers: :any,
             methods: %i[get post patch put delete options head],
             expose: %w[X-Request-Id Retry-After],
             credentials: false,
             max_age: 600
  end
end
