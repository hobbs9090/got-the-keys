require "yaml"

module DemoData
  class ScenarioCatalog
    def initialize(directory: Rails.root.join("db/demo_scenarios"))
      @directory = directory
    end

    def all
      scenario_paths.map { |path| load_file(path) }
    end

    def fetch!(key)
      all.find { |scenario| scenario.fetch(:key) == key } || raise(KeyError, "Unknown demo scenario: #{key}")
    end

    private

    attr_reader :directory

    def scenario_paths
      Dir[directory.join("*.yml")].sort
    end

    def load_file(path)
      payload = YAML.safe_load(File.read(path), permitted_classes: [Date, Time], aliases: false) || {}
      payload.deep_symbolize_keys
    end
  end
end
