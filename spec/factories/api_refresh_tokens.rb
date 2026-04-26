FactoryBot.define do
  factory :api_refresh_token do
    association :user
    token_digest { Digest::SHA256.hexdigest(SecureRandom.urlsafe_base64(32)) }
    sequence(:device_id) { |n| "device-#{n}-#{SecureRandom.uuid}" }
    device_name { "Test iPhone" }
    user_agent  { "GotTheKeys/1.0 iOS" }
    ip_address  { "127.0.0.1" }
    expires_at  { 30.days.from_now }
  end
end
