require "rails_helper"

RSpec.describe ReleaseBuildMetadata do
  describe ".load" do
    it "returns an empty hash when the file is missing" do
      expect(described_class.load("/tmp/missing-build-info.json")).to eq({})
    end
  end

  describe ".current_revision" do
    it "returns the current short git sha for a git repository" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", "/tmp/example-repo", "rev-parse", "--short=7", "HEAD")
        .and_return(["fd481e9\n", instance_double(Process::Status, success?: true)])

      expect(described_class.current_revision("/tmp/example-repo")).to eq("fd481e9")
    end

    it "returns nil when git cannot provide a revision" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", "/tmp/example-repo", "rev-parse", "--short=7", "HEAD")
        .and_return(["", instance_double(Process::Status, success?: false)])

      expect(described_class.current_revision("/tmp/example-repo")).to be_nil
    end
  end

  describe ".workspace_dirty?" do
    it "returns true when git reports uncommitted changes" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", "/tmp/example-repo", "status", "--porcelain")
        .and_return([" M app/models/user.rb\n", instance_double(Process::Status, success?: true)])

      expect(described_class.workspace_dirty?("/tmp/example-repo")).to be(true)
    end

    it "returns false when the git workspace is clean" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", "/tmp/example-repo", "status", "--porcelain")
        .and_return(["", instance_double(Process::Status, success?: true)])

      expect(described_class.workspace_dirty?("/tmp/example-repo")).to be(false)
    end
  end

  describe ".payload" do
    it "uses the deployed revision and requested build number when both are present" do
      payload = described_class.payload(
        previous_metadata: { "build_number" => "9" },
        current_revision: "abcdef123456",
        requested_build_sha: "stale12",
        requested_build_number: "42",
        deployed_at: "2026-03-26T09:00:00Z"
      )

      expect(payload).to eq(
        build_sha: "abcdef1",
        build_number: "42",
        deployed_at: "2026-03-26T09:00:00Z"
      )
    end

    it "falls back to the requested build sha when no deployed revision is available" do
      payload = described_class.payload(
        previous_metadata: {},
        current_revision: nil,
        requested_build_sha: "abc1234",
        deployed_at: "2026-03-26T09:00:00Z"
      )

      expect(payload[:build_sha]).to eq("abc1234")
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

  describe ".configured_build_sha" do
    it "prefers persisted deploy metadata over an environment value" do
      expect(
        described_class.configured_build_sha(
          build_metadata: { "build_sha" => "fresh12" },
          env_build_sha: "stale34",
          current_revision: "local56"
        )
      ).to eq("fresh12")
    end

    it "uses the environment value when no persisted metadata exists" do
      expect(
        described_class.configured_build_sha(
          build_metadata: {},
          env_build_sha: "env1234",
          current_revision: "local56"
        )
      ).to eq("env1234")
    end
  end
end
