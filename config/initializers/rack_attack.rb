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
