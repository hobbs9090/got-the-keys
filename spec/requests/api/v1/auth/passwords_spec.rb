require "rails_helper"

RSpec.describe "Api::V1::Auth::Passwords", type: :request do
  let!(:user) { create(:user) }

  describe "POST /api/v1/auth/password" do
    it "returns 202 for a known email and triggers Devise" do
      expect(User).to receive(:find_by).and_call_original
      expect_any_instance_of(User).to receive(:send_reset_password_instructions)
      post "/api/v1/auth/password",
           params: { email: user.email }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:accepted)
    end

    it "returns 202 for an unknown email (no user enumeration)" do
      post "/api/v1/auth/password",
           params: { email: "ghost@example.com" }.to_json,
           headers: api_json_headers
      expect(response).to have_http_status(:accepted)
    end
  end

  describe "PATCH /api/v1/auth/password" do
    it "updates the password with a valid token" do
      raw_token = user.send(:set_reset_password_token)
      patch "/api/v1/auth/password",
            params: {
              reset_password_token:  raw_token,
              password:              "newpassword123",
              password_confirmation: "newpassword123"
            }.to_json,
            headers: api_json_headers
      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?("newpassword123")).to be(true)
    end

    it "returns validation errors for a bad token" do
      patch "/api/v1/auth/password",
            params: {
              reset_password_token:  "invalid",
              password:              "newpassword123",
              password_confirmation: "newpassword123"
            }.to_json,
            headers: api_json_headers
      expect(response).to have_http_status(:unprocessable_content)
      expect(json_body.dig("error", "code")).to eq("validation_failed")
    end

    it "requires the reset_password_token param" do
      patch "/api/v1/auth/password",
            params: { password: "x" }.to_json,
            headers: api_json_headers
      expect(response).to have_http_status(:bad_request)
    end
  end
end
