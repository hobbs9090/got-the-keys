require "rails_helper"

RSpec.describe "Health check", type: :request do
  it "returns a plain OK response" do
    get "/up"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/plain")
    expect(response.body).to eq("OK")
  end

  it "returns 503 when a dependency check fails" do
    allow_any_instance_of(HealthController).to receive(:cache_ready?).and_return(false)

    get "/up"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to eq("FAILED: cache")
  end
end
