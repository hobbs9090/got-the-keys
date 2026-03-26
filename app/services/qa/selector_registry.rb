require "yaml"

module Qa
  class SelectorRegistry
    def initialize(path: Rails.root.join("config/selector_contracts.yml"))
      @path = path
    end

    def all
      payload.fetch(:selectors).map(&:deep_symbolize_keys)
    end

    def grouped_by_surface
      all.group_by { |entry| entry.fetch(:surface) }
    end

    private

    attr_reader :path

    def payload
      @payload ||= (YAML.safe_load(File.read(path), aliases: false) || {}).deep_symbolize_keys
    end
  end
end
