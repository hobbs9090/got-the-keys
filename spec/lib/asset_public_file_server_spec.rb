require "rails_helper"
require "rack/mock"
require "tmpdir"

RSpec.describe AssetPublicFileServer do
  let(:app) do
    lambda do |_env|
      [404, { "Content-Type" => "text/plain" }, ["fallback"]]
    end
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @public_root = Pathname.new(dir)
      FileUtils.mkdir_p(@public_root.join("assets"))
      File.write(@public_root.join("assets", "application-test.css"), "body { color: #123456; }")

      example.run
    end
  end

  subject(:middleware) { described_class.new(app, @public_root) }

  it "adds immutable cache headers for asset requests" do
    status, headers, _body = middleware.call(Rack::MockRequest.env_for("/assets/application-test.css"))
    normalized_headers = headers.transform_keys(&:downcase)

    expect(status).to eq(200)
    expect(normalized_headers["cache-control"]).to eq("public, max-age=31536000, immutable")
    expect(normalized_headers["content-type"]).to start_with("text/css")
  end

  it "passes through missing asset requests" do
    status, headers, body = middleware.call(Rack::MockRequest.env_for("/assets/missing.css"))

    expect(status).to eq(404)
    expect(headers["Content-Type"]).to eq("text/plain")
    expect(body.each.to_a.join).to eq("fallback")
  end

  it "passes through non-asset requests" do
    status, headers, body = middleware.call(Rack::MockRequest.env_for("/robots.txt"))

    expect(status).to eq(404)
    expect(headers["Content-Type"]).to eq("text/plain")
    expect(body.each.to_a.join).to eq("fallback")
  end
end
