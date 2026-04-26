require "rails_helper"

RSpec.describe "POST /api/v1/auth/refresh", type: :request do
  let!(:user)  { create(:user) }
  let(:tokens) { api_login_for(user, device_id: "ios-1") }

  it "rotates the refresh token and issues a new access token" do
    original_refresh = tokens[:refresh_token]

    post "/api/v1/auth/refresh",
         params: { refresh_token: original_refresh }.to_json,
         headers: api_json_headers
    expect(response).to have_http_status(:ok)
    body = json_body
    expect(body["access_token"]).to be_present
    expect(body["refresh_token"]).to be_present
    expect(body["refresh_token"]).not_to eq(original_refresh)
  end

  it "revokes the old refresh token after rotation" do
    original = tokens[:refresh_token]
    post "/api/v1/auth/refresh", params: { refresh_token: original }.to_json, headers: api_json_headers
    expect(response).to have_http_status(:ok)

    # Try the original again — must fail.
    post "/api/v1/auth/refresh", params: { refresh_token: original }.to_json, headers: api_json_headers
    expect(response).to have_http_status(:unauthorized)
    expect(json_body.dig("error", "code")).to eq("refresh_invalid")
  end

  it "rejects unknown refresh tokens" do
    post "/api/v1/auth/refresh",
         params: { refresh_token: "rt_99999.totally-fake" }.to_json,
         headers: api_json_headers
    expect(response).to have_http_status(:unauthorized)
  end

  it "treats reuse of a revoked token as compromise" do
    original = tokens[:refresh_token]

    # First rotation succeeds.
    post "/api/v1/auth/refresh", params: { refresh_token: original }.to_json, headers: api_json_headers
    expect(response).to have_http_status(:ok)

    old_jti = user.reload.jti

    # Second use of the now-revoked token should burn down all the user's
    # refresh tokens AND rotate the JTI.
    post "/api/v1/auth/refresh", params: { refresh_token: original }.to_json, headers: api_json_headers
    expect(response).to have_http_status(:unauthorized)
    expect(user.reload.jti).not_to eq(old_jti)
    expect(ApiRefreshToken.where(user: user).active.count).to eq(0)
  end

  it "requires a refresh_token param" do
    post "/api/v1/auth/refresh", params: {}.to_json, headers: api_json_headers
    expect(response).to have_http_status(:unauthorized)
    expect(json_body.dig("error", "code")).to eq("refresh_invalid")
  end
end
