FactoryBot.define do
  factory :admin do
    email 'admin@test.com'
    language 'en'
    password 'changeme'
    password_confirmation 'changeme'
    # required if the Devise Confirmable module is used
    # confirmed_at Time.now
  end
end