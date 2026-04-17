require "rails_helper"

RSpec.describe "robots.txt", type: :request do
  let(:seo_config) { Rails.configuration.x.got_the_keys }

  around do |example|
    original_public_indexing_enabled = seo_config.public_indexing_enabled
    original_public_indexing_env = ENV["PUBLIC_INDEXING_ENABLED"]
    original_allow_indexing_env = ENV["ALLOW_INDEXING"]
    seo_config.public_indexing_enabled = default_public_indexing_enabled
    ENV["PUBLIC_INDEXING_ENABLED"] = public_indexing_enabled
    ENV.delete("ALLOW_INDEXING")
    example.run
  ensure
    seo_config.public_indexing_enabled = original_public_indexing_enabled
    ENV["PUBLIC_INDEXING_ENABLED"] = original_public_indexing_env
    ENV["ALLOW_INDEXING"] = original_allow_indexing_env
  end

  context "when the environment default disables indexing" do
    let(:default_public_indexing_enabled) { false }
    let(:public_indexing_enabled) { nil }

    it "disallows crawling" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to eq("User-agent: *\nDisallow: /\n")
    end
  end

  context "when the environment default enables indexing" do
    let(:default_public_indexing_enabled) { true }
    let(:public_indexing_enabled) { nil }

    it "allows crawling" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to eq("User-agent: *\nAllow: /\n")
    end
  end

  context "when PUBLIC_INDEXING_ENABLED overrides the environment default" do
    let(:default_public_indexing_enabled) { false }
    let(:public_indexing_enabled) { "true" }

    it "allows crawling" do
      get "/robots.txt"

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/plain")
      expect(response.body).to eq("User-agent: *\nAllow: /\n")
    end
  end
end
