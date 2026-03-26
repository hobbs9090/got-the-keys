# frozen_string_literal: true

require "yaml"

module Ci
  class RspecPerformanceBaseline
    DEFAULT_TOP_EXAMPLES = 10
    DEFAULT_SUITE_WARNING_SECONDS = 12.0
    DEFAULT_SLOW_EXAMPLE_WARNING_SECONDS = 4.0
    DEFAULT_WARNING_EXAMPLES_LIMIT = 3

    attr_reader :top_examples, :suite_warning_seconds, :slow_example_warning_seconds, :warning_examples_limit

    def initialize(top_examples:, suite_warning_seconds:, slow_example_warning_seconds:, warning_examples_limit:)
      @top_examples = top_examples.to_i
      @suite_warning_seconds = suite_warning_seconds.to_f
      @slow_example_warning_seconds = slow_example_warning_seconds.to_f
      @warning_examples_limit = warning_examples_limit.to_i
    end

    def self.load(path)
      raw =
        if path && File.exist?(path)
          YAML.safe_load(File.read(path), permitted_classes: [], aliases: false) || {}
        else
          {}
        end

      new(
        top_examples: raw.fetch("top_examples", DEFAULT_TOP_EXAMPLES),
        suite_warning_seconds: raw.fetch("suite_warning_seconds", DEFAULT_SUITE_WARNING_SECONDS),
        slow_example_warning_seconds: raw.fetch("slow_example_warning_seconds", DEFAULT_SLOW_EXAMPLE_WARNING_SECONDS),
        warning_examples_limit: raw.fetch("warning_examples_limit", DEFAULT_WARNING_EXAMPLES_LIMIT)
      )
    end
  end

  class RspecPerformanceReport
    Example = Struct.new(:file_path, :line_number, :full_description, :run_time, keyword_init: true) do
      def location
        [file_path, line_number].compact.join(":")
      end
    end

    def initialize(report_data:, baseline:)
      @report_data = report_data
      @baseline = baseline
    end

    def slow_examples
      Array(report_data["examples"])
        .map { |example| build_example(example) }
        .compact
        .sort_by { |example| -example.run_time }
        .first(baseline.top_examples)
    end

    def suite_duration
      report_data.dig("summary", "duration").to_f
    end

    def warnings
      messages = []

      if suite_duration > baseline.suite_warning_seconds
        messages << "RSpec suite duration #{format_duration(suite_duration)} exceeded the warning baseline of #{format_duration(baseline.suite_warning_seconds)}."
      end

      slow_examples
        .select { |example| example.run_time > baseline.slow_example_warning_seconds }
        .first(baseline.warning_examples_limit)
        .each do |example|
          messages << "Slow example #{format_duration(example.run_time)} exceeded the warning baseline of #{format_duration(baseline.slow_example_warning_seconds)}: #{example.location} #{truncate(example.full_description)}"
        end

      messages
    end

    def markdown_lines
      lines = []
      examples = slow_examples
      return lines if examples.empty?

      lines << ""
      lines << "## Slowest Examples"
      lines << ""
      lines << "| Location | Example | Run Time |"
      lines << "| --- | --- | --- |"

      examples.each do |example|
        lines << "| `#{example.location}` | #{truncate(example.full_description)} | #{format_duration(example.run_time)} |"
      end

      lines << ""
      lines << "## Performance Baseline"
      lines << ""
      lines << "| Metric | Current | Warning Threshold |"
      lines << "| --- | --- | --- |"
      lines << "| Suite duration | #{format_duration(suite_duration)} | #{format_duration(baseline.suite_warning_seconds)} |"
      lines << "| Slow example warning | #{format_duration(examples.first.run_time)} | #{format_duration(baseline.slow_example_warning_seconds)} |"

      lines
    end

    private

    attr_reader :report_data, :baseline

    def build_example(example)
      run_time = example["run_time"]
      return if run_time.nil?

      Example.new(
        file_path: normalize_file_path(example["file_path"]),
        line_number: example["line_number"],
        full_description: example["full_description"] || example["description"],
        run_time: run_time.to_f
      )
    end

    def normalize_file_path(path)
      path.to_s.sub(%r{\A\./}, "")
    end

    def format_duration(seconds)
      format("%.2fs", seconds.to_f)
    end

    def truncate(text, limit = 180)
      value = text.to_s.strip
      return value if value.length <= limit

      "#{value[0, limit - 1]}..."
    end
  end
end
