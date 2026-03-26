require "rails_helper"

RSpec.describe ReleaseBuildMetadata do
  describe ".load" do
    it "returns an empty hash when the file is missing" do
      expect(described_class.load("/tmp/missing-build-info.json")).to eq({})
    end
  end

  describe ".payload" do
    it "uses the requested build number when it is newer than the previous build" do
      payload = described_class.payload(
        previous_metadata: { "build_number" => "9" },
        current_revision: "abcdef123456",
        requested_build_sha: "abc1234",
        requested_build_number: "42",
        deployed_at: "2026-03-26T09:00:00Z"
      )

      expect(payload).to eq(
        build_sha: "abc1234",
        build_number: "42",
        deployed_at: "2026-03-26T09:00:00Z"
      )
    end

    it "increments the previous build number when none is provided" do
      payload = described_class.payload(
        previous_metadata: { "build_number" => "9" },
        current_revision: "abcdef123456",
        deployed_at: "2026-03-26T09:00:00Z"
      )

      expect(payload).to eq(
        build_sha: "abcdef1",
        build_number: "10",
        deployed_at: "2026-03-26T09:00:00Z"
      )
    end

    it "starts at build 1 when no previous metadata exists" do
      payload = described_class.payload(
        previous_metadata: {},
        current_revision: "abcdef123456",
        deployed_at: "2026-03-26T09:00:00Z"
      )

      expect(payload[:build_number]).to eq("1")
    end
  end
end
