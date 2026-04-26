# Encodes and decodes JWT access tokens for the JSON API.
#
# devise-jwt is configured (config/initializers/devise_jwt.rb) but its automatic
# dispatch is disabled — we issue tokens explicitly from the auth controllers so
# the flow is easy to reason about. devise-jwt's Warden strategy is not used for
# verification either: we decode here and check the JTI against User#jti.
#
# Tokens are HS256-signed, expire after EXPIRATION_SECONDS, and carry:
#
#   {
#     "sub":  "<user_id>",
#     "jti":  "<user.jti>",
#     "iat":  <issued-at-epoch>,
#     "exp":  <expires-at-epoch>,
#     "aud":  "ios" | "web" | "generic",
#     "scp":  "user"
#   }
class JwtTokenIssuer
  EXPIRATION_SECONDS = 15 * 60
  ALGORITHM          = "HS256".freeze
  DEFAULT_AUDIENCE   = "ios".freeze

  class << self
    def issue(user, audience: DEFAULT_AUDIENCE)
      now     = Time.current.to_i
      payload = {
        "sub" => user.id.to_s,
        "jti" => user.jti.to_s,
        "iat" => now,
        "exp" => now + EXPIRATION_SECONDS,
        "aud" => audience,
        "scp" => "user"
      }

      token = JWT.encode(payload, secret, ALGORITHM)
      [token, payload]
    end

    # Returns the decoded payload, or nil if the token is malformed/expired.
    def decode(token)
      JWT.decode(token, secret, true, { algorithm: ALGORITHM, verify_expiration: true }).first
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError
      nil
    end

    def expires_in
      EXPIRATION_SECONDS
    end

    private

    def secret
      Rails.application.credentials.dig(:jwt_secret_key) ||
        ENV["DEVISE_JWT_SECRET_KEY"] ||
        Rails.application.secret_key_base
    end
  end
end
