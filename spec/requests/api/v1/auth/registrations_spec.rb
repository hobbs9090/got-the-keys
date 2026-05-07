require "rails_helper"

RSpec.describe "POST /api/v1/auth/register", type: :request do
  let(:valid_params) do
    {
      email:            "newbuyer@example.com",
      password:         "correcthorsebattery1",
      first_name:       "Sam",
      last_name:        "Buyer",
      mobile_number:    "07595 123456",
      language:         "en",
      terms_of_service: true,
      device_id:        "ios-device-1",
      device_name:      "Sam's iPhone"
    }
  end

  it "creates the user and returns a token pair" do
    expect {
      post "/api/v1/auth/register", params: valid_params.to_json, headers: api_json_headers
    }.to change(User, :count).by(1).and change(ApiRefreshToken, :count).by(1)

    expect(response).to have_http_status(:created)
    body = json_body
    expect(body["user"]).to include("email" => "newbuyer@example.com")
    expect(body["access_token"]).to be_present
    expect(body["refresh_token"]).to start_with("rt_")
    expect(body["expires_in"]).to eq(JwtTokenIssuer::EXPIRATION_SECONDS)
  end

  it "rejects registrations missing device_id" do
    post "/api/v1/auth/register",
         params: valid_params.except(:device_id).to_json,
         headers: api_json_headers
    expect(response).to have_http_status(:bad_request)
    expect(json_body.dig("error", "code")).to eq("bad_request")
  end

  it "returns validation errors for invalid input" do
    post "/api/v1/auth/register",
         params: valid_params.merge(email: "not-an-email", first_name: "").to_json,
         headers: api_json_headers
    expect(response).to have_http_status(:unprocessable_content)
    body = json_body
    expect(body.dig("error", "code")).to eq("validation_failed")
    expect(body.dig("error", "details").map { |d| d["field"] }).to include("email", "first_name")
  end

  it "rejects duplicate email" do
    create(:user, email: "newbuyer@example.com")
    post "/api/v1/auth/register", params: valid_params.to_json, headers: api_json_headers
    expect(response).to have_http_status(:unprocessable_content)
    expect(json_body.dig("error", "details").map { |d| d["field"] }).to include("email")
  end
end
