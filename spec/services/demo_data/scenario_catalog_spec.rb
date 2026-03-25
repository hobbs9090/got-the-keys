require "rails_helper"
require "tmpdir"

RSpec.describe DemoData::ScenarioCatalog do
  def write_scenario(directory, filename, payload)
    File.write(File.join(directory, filename), YAML.dump(payload.deep_stringify_keys))
  end

  it "loads scenarios from the given directory in filename order" do
    Dir.mktmpdir do |directory|
      write_scenario(directory, "b.yml", { key: "beta", name: "Beta" })
      write_scenario(directory, "a.yml", { key: "alpha", name: "Alpha" })

      catalog = described_class.new(directory: Pathname(directory))

      expect(catalog.all.map { |scenario| scenario[:key] }).to eq(%w[alpha beta])
    end
  end

  it "fetches a scenario by key" do
    Dir.mktmpdir do |directory|
      write_scenario(directory, "baseline.yml", { key: "baseline", name: "Baseline" })

      catalog = described_class.new(directory: Pathname(directory))

      expect(catalog.fetch!("baseline")).to include(key: "baseline", name: "Baseline")
    end
  end

  it "raises a helpful error for an unknown scenario key" do
    Dir.mktmpdir do |directory|
      write_scenario(directory, "baseline.yml", { key: "baseline", name: "Baseline" })

      catalog = described_class.new(directory: Pathname(directory))

      expect { catalog.fetch!("missing") }.to raise_error(KeyError, "Unknown demo scenario: missing")
    end
  end
end
