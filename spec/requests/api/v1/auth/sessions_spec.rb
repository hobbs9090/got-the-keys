require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  let(:password) { "correcthorsebattery1" }
  let!(:user)    { create(:user, password: password, password_confirmation: password) }

  describe "POST /api/v1/auth/login" do
    it "returns a token pair for valid credentials" do
      post "/api/v1/auth/login",
           params: { email: user.email, password: password, device_id: "ios-1" }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:ok)
      body = json_body
      expect(body["access_token"]).to be_present
      expect(body["refresh_token"]).to start_with("rt_")
      expect(body.dig("user", "id")).to eq(user.id)
    end

    it "increments sign-in counters" do
      expect {
        post "/api/v1/auth/login",
             params: { email: user.email, password: password, device_id: "ios-1" }.to_json,
             headers: api_json_headers
      }.to change { user.reload.sign_in_count }.by(1)
    end

    it "returns 401 with invalid_credentials code on bad password" do
      post "/api/v1/auth/login",
           params: { email: user.email, password: "wrong", device_id: "ios-1" }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
      expect(json_body.dig("error", "code")).to eq("unauthenticated")
    end

    it "returns 401 with paranoid wording on unknown email" do
      post "/api/v1/auth/login",
           params: { email: "ghost@example.com", password: password, device_id: "ios-1" }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 423 once the account is locked" do
      user.lock_access!
      post "/api/v1/auth/login",
           params: { email: user.email, password: password, device_id: "ios-1" }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:locked)
      expect(json_body.dig("error", "code")).to eq("locked")
    end

    it "rejects logins missing device_id" do
      post "/api/v1/auth/login",
           params: { email: user.email, password: password }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    let(:tokens) { api_login_for(user) }

    it "revokes the refresh token and rotates the user's JTI" do
      old_jti = user.jti
      delete "/api/v1/auth/logout",
             params:  { refresh_token: tokens[:refresh_token] }.to_json,
             headers: api_auth_headers(tokens[:access_token])
      expect(response).to have_http_status(:ok)
      expect(json_body["logged_out"]).to be(true)
      expect(user.reload.jti).not_to eq(old_jti)
    end

    it "rejects requests without a valid bearer token" do
      delete "/api/v1/auth/logout",
             params:  { refresh_token: tokens[:refresh_token] }.to_json,
             headers: api_json_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
