require "rails_helper"

RSpec.describe "Health check", type: :request do
  it "returns a plain OK response" do
    get "/up"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain")
    expect(response.body).to eq("OK")
  end
end
