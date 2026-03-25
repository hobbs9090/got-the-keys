require "rails_helper"

RSpec.describe "Cookie preferences", type: :request do
  it "stores an essential-only choice and redirects back to the supplied path" do
    patch cookie_preferences_path, params: {
      preference: "essential",
      return_to: contact_us_path
    }

    expect(response).to redirect_to(contact_us_path)
    expect(response.cookies["gotthekeys_cookie_consent"]).to eq("essential")
  end

  it "ignores unsafe return urls" do
    patch cookie_preferences_path, params: {
      preference: "all",
      return_to: "https://example.com/elsewhere"
    }

    expect(response).to redirect_to(cookie_policy_index_path(anchor: "cookie-preferences"))
    expect(response.cookies["gotthekeys_cookie_consent"]).to eq("all")
  end
end
