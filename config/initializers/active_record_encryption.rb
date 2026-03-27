require "base64"

encryption_credentials = Rails.application.credentials.active_record_encryption || {}
secret_key_base = Rails.application.secret_key_base
key_generator = ActiveSupport::KeyGenerator.new(secret_key_base, iterations: 1_000)

derive_encryption_key = lambda do |label|
  Base64.strict_encode64(key_generator.generate_key("got_the_keys:active_record_encryption:#{label}", 32))
end

Rails.application.config.active_record.encryption.primary_key =
  ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].presence ||
  encryption_credentials[:primary_key].presence ||
  derive_encryption_key.call("primary_key")

Rails.application.config.active_record.encryption.deterministic_key =
  ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"].presence ||
  encryption_credentials[:deterministic_key].presence ||
  derive_encryption_key.call("deterministic_key")

Rails.application.config.active_record.encryption.key_derivation_salt =
  ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"].presence ||
  encryption_credentials[:key_derivation_salt].presence ||
  derive_encryption_key.call("key_derivation_salt")
