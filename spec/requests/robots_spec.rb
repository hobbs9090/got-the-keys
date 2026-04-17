require "rails_helper"

RSpec.describe "robots.txt", type: :request do
  around do |example|
    original = ENV["ALLOW_INDEXING"]
    ENV["ALLOW_INDEXING"] = allow_indexing
    example.run
  ensure
    ENV["ALLOW_INDEXING"] = original
  end

  context "when indexing is disabled" do
    let(:allow_indexing) { "false" }

    it "disallows crawling" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to eq("User-agent: *\nDisallow: /\n")
    end
  end

  context "when indexing is enabled" do
    let(:allow_indexing) { "true" }

    it "allows crawling" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to eq("User-agent: *\nAllow: /\n")
    end
  end
end
