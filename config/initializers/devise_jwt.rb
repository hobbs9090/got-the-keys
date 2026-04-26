# Configures devise-jwt. We do NOT use devise-jwt's automatic dispatch via the
# Devise sessions controller — the JSON API has its own auth controllers under
# Api::V1::Auth that issue tokens explicitly. devise-jwt is here purely for the
# Warden strategy used by Api::V1::BaseController#authenticate_api_user! and the
# JTIMatcher revocation strategy mixed into User.
#
# The signing secret reuses Rails' credentials, falling back to a Devise-derived
# value in development/test so the suite runs without secrets configured.
Devise.setup do |config|
  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.dig(:jwt_secret_key) ||
                 ENV["DEVISE_JWT_SECRET_KEY"] ||
                 Rails.application.secret_key_base

    jwt.dispatch_requests = []   # we issue tokens manually, never via Devise
    jwt.revocation_requests = [] # we revoke manually too
    jwt.expiration_time   = 15.minutes.to_i
    jwt.aud_header        = "JWT_AUD"
    jwt.request_formats   = { user: [:json] }
  end
end
