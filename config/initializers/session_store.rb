GotTheKeys::Application.config.session_store :cookie_store,
  key: '_got_the_keys_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :strict
