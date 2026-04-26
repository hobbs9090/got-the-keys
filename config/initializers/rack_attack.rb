Rack::Attack.throttle("sign_in/ip", limit: 10, period: 5.minutes) do |req|
  req.ip if req.path == "/users/sign_in" && req.post?
end

Rack::Attack.throttle("sign_in/email", limit: 5, period: 5.minutes) do |req|
  if req.path == "/users/sign_in" && req.post?
    req.params.dig("user", "email").to_s.downcase.presence
  end
end

Rack::Attack.throttle("admin_sign_in/ip", limit: 5, period: 5.minutes) do |req|
  req.ip if req.path == "/admins/sign_in" && req.post?
end

Rack::Attack.throttle("admin_sign_in/email", limit: 5, period: 5.minutes) do |req|
  if req.path == "/admins/sign_in" && req.post?
    req.params.dig("admin", "email").to_s.downcase.presence
  end
end

Rack::Attack.throttle("password_reset/ip", limit: 5, period: 10.minutes) do |req|
  req.ip if req.path == "/users/password" && req.post?
end

Rack::Attack.throttle("password_reset/email", limit: 3, period: 10.minutes) do |req|
  if req.path == "/users/password" && req.post?
    req.params.dig("user", "email").to_s.downcase.presence
  end
end

Rack::Attack.throttle("account_unlock/ip", limit: 5, period: 10.minutes) do |req|
  req.ip if req.path == "/users/unlock" && req.post?
end

Rack::Attack.throttle("registration/ip", limit: 10, period: 10.minutes) do |req|
  req.ip if req.path == "/users/register" && req.post?
end

# ----------------------------------------------------------------------------
# JSON API throttles. See docs/api/v1-spec.md §8.4.
# ----------------------------------------------------------------------------
Rack::Attack.throttle("api_login/ip", limit: 10, period: 5.minutes) do |req|
  req.ip if req.path == "/api/v1/auth/login" && req.post?
end

Rack::Attack.throttle("api_login/email", limit: 5, period: 5.minutes) do |req|
  if req.path == "/api/v1/auth/login" && req.post?
    req.params["email"].to_s.downcase.presence
  end
end

Rack::Attack.throttle("api_register/ip", limit: 10, period: 10.minutes) do |req|
  req.ip if req.path == "/api/v1/auth/register" && req.post?
end

Rack::Attack.throttle("api_password/ip", limit: 5, period: 10.minutes) do |req|
  req.ip if req.path == "/api/v1/auth/password" && req.post?
end

Rack::Attack.throttle("api_password/email", limit: 3, period: 10.minutes) do |req|
  if req.path == "/api/v1/auth/password" && req.post?
    req.params["email"].to_s.downcase.presence
  end
end

Rack::Attack.throttle("api_refresh/ip", limit: 60, period: 1.minute) do |req|
  req.ip if req.path == "/api/v1/auth/refresh" && req.post?
end

# Catch-all for authenticated API requests, keyed by the bearer token's user id
# (decoded eagerly here without verifying signature — close enough for rate
# limiting and avoids re-decoding the JWT inside the strategy).
Rack::Attack.throttle("api/user", limit: 600, period: 1.minute) do |req|
  next unless req.path.start_with?("/api/")

  header = req.env["HTTP_AUTHORIZATION"].to_s
  next if header.blank?

  scheme, token = header.split(" ", 2)
  next unless scheme&.casecmp("bearer")&.zero? && token.present?

  begin
    payload, _h = JWT.decode(token, nil, false)
    payload && payload["sub"].presence
  rescue StandardError
    nil
  end
end

# Anonymous catalogue browsing.
Rack::Attack.throttle("api/anon", limit: 300, period: 1.minute) do |req|
  if req.path.start_with?("/api/") && req.env["HTTP_AUTHORIZATION"].to_s.empty?
    req.ip
  end
end

Rack::Attack.throttled_responder = ->(req) {
  match_data = req.env["rack.attack.match_data"]
  now        = match_data[:epoch_time]
  retry_after = match_data[:period] - (now % match_data[:period])

  [
    429,
    {
      "Content-Type"  => "text/plain",
      "Retry-After"   => retry_after.to_s
    },
    ["Too many requests. Please try again later."]
  ]
}
