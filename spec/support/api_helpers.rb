module ApiHelpers
  def json_body
    JSON.parse(response.body)
  end

  # Issues a fresh JWT + refresh-token pair for the given user and returns the
  # pair as a hash, suitable for use in request-spec headers.
  def api_login_for(user, device_id: SecureRandom.uuid)
    access, _payload = JwtTokenIssuer.issue(user)
    _record, refresh = ApiRefreshToken.issue!(user: user, device_id: device_id, device_name: "Spec")
    { access_token: access, refresh_token: refresh }
  end

  def api_auth_headers(user_or_token, **extra)
    token = user_or_token.is_a?(User) ? api_login_for(user_or_token)[:access_token] : user_or_token
    {
      "Authorization" => "Bearer #{token}",
      "Accept"        => "application/json",
      "Content-Type"  => "application/json"
    }.merge(extra)
  end

  def api_json_headers(extra = {})
    { "Accept" => "application/json", "Content-Type" => "application/json" }.merge(extra)
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
