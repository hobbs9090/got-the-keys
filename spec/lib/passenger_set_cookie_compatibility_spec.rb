require "rails_helper"

RSpec.describe PassengerSetCookieCompatibility do
  it "normalizes array-based Set-Cookie headers for Passenger-style servers" do
    app = lambda do |_env|
      [
        302,
        {
          "set-cookie" => [
            "gotthekeys_cookie_consent=all; path=/; secure",
            "_got_the_keys_session=abc123; path=/; secure; httponly"
          ]
        },
        []
      ]
    end

    _status, headers, _body = described_class.new(app).call({})

    expect(headers["set-cookie"]).to eq(
      "gotthekeys_cookie_consent=all; path=/; secure\n" \
      "_got_the_keys_session=abc123; path=/; secure; httponly"
    )
  end

  it "leaves string Set-Cookie headers unchanged" do
    app = lambda do |_env|
      [200, { "Set-Cookie" => "gotthekeys_cookie_consent=essential; path=/" }, []]
    end

    _status, headers, _body = described_class.new(app).call({})

    expect(headers["Set-Cookie"]).to eq("gotthekeys_cookie_consent=essential; path=/")
  end
end
