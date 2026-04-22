require "rails_helper"

RSpec.describe "Cookie preferences", type: :request do
  it "stores an essential-only choice and redirects back to the supplied path" do
    patch cookie_preferences_path, params: {
      preference: "essential",
      return_to: contact_us_path
    }

    expect(response).to redirect_to(contact_us_path)
    expect(response.cookies["gotthekeys_cookie_consent"]).to eq("essential")
    expect(Array(response.headers["Set-Cookie"]).join("\n")).to include("gotthekeys_cookie_consent=essential")
  end

  it "ignores unsafe return urls" do
    patch cookie_preferences_path, params: {
      preference: "all",
      return_to: "https://example.com/elsewhere"
    }

    expect(response).to redirect_to(cookie_policy_index_path(anchor: "cookie-preferences"))
    expect(response.cookies["gotthekeys_cookie_consent"]).to eq("all")
  end

  it "ignores invalid preferences and does not set the consent cookie" do
    patch cookie_preferences_path, params: {
      preference: "marketing",
      return_to: contact_us_path
    }

    expect(response).to redirect_to(contact_us_path)
    expect(response.cookies["gotthekeys_cookie_consent"]).to be_nil
    expect(response.headers["Set-Cookie"].to_s).not_to include("gotthekeys_cookie_consent")
  end

  it "rejects protocol-relative return urls" do
    patch cookie_preferences_path, params: {
      preference: "all",
      return_to: "//example.com/elsewhere"
    }

    expect(response).to redirect_to(cookie_policy_index_path(anchor: "cookie-preferences"))
    expect(response.cookies["gotthekeys_cookie_consent"]).to eq("all")
  end
end
