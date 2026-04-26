require "rails_helper"

RSpec.describe "Api::V1::Me", type: :request do
  let!(:user) { create(:user) }

  describe "GET /api/v1/me" do
    it "returns the current user" do
      get "/api/v1/me", headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(json_body.dig("user", "id")).to eq(user.id)
      expect(json_body.dig("user", "email")).to eq(user.email)
    end

    it "rejects requests without a bearer token" do
      get "/api/v1/me"
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with an expired/invalid token" do
      get "/api/v1/me", headers: { "Authorization" => "Bearer not-a-real-jwt" }
      expect(response).to have_http_status(:unauthorized)
      expect(json_body.dig("error", "code")).to eq("token_expired")
    end
  end

  describe "PATCH /api/v1/me" do
    it "updates allowed fields" do
      patch "/api/v1/me",
            params: { first_name: "Updated", last_name: "Name" }.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(user.reload.first_name).to eq("Updated")
    end

    it "ignores attempts to set fields not in the allow-list (mass assignment safety)" do
      patch "/api/v1/me",
            params: { admin_provisioned: true, encrypted_password: "x" }.to_json,
            headers: api_auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(user.reload.admin_provisioned).to be(false)
    end
  end

  describe "DELETE /api/v1/me" do
    it "anonymizes the user and revokes refresh tokens" do
      tokens = api_login_for(user)
      expect {
        delete "/api/v1/me",
               headers: api_auth_headers(tokens[:access_token])
      }.to change { ApiRefreshToken.where(user: user).active.count }.to(0)
      expect(response).to have_http_status(:ok)
      reloaded = user.reload
      expect(reloaded.email).to start_with("deleted-")
      expect(reloaded.first_name).to eq("Deleted")
    end
  end
end
