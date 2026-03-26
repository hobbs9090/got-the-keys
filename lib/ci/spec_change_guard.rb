# frozen_string_literal: true

module Ci
  class ChangeRange
    NULL_SHA = '0' * 40

    attr_reader :base_sha, :head_sha, :diff_mode

    def initialize(base_sha:, head_sha:, diff_mode:)
      @base_sha = presence(base_sha)
      @head_sha = presence(head_sha)
      @diff_mode = diff_mode
    end

    def self.from_github(env:, payload:)
      case env['GITHUB_EVENT_NAME']
      when 'pull_request', 'pull_request_target'
        new(
          base_sha: payload.dig('pull_request', 'base', 'sha'),
          head_sha: payload.dig('pull_request', 'head', 'sha'),
          diff_mode: :three_dot
        )
      when 'push'
        before = payload['before']

        new(
          base_sha: before == NULL_SHA ? nil : before,
          head_sha: payload['after'] || env['GITHUB_SHA'],
          diff_mode: before == NULL_SHA ? :single_commit : :two_dot
        )
      else
        new(base_sha: nil, head_sha: env['GITHUB_SHA'], diff_mode: :single_commit)
      end
    end

    def complete?
      head_sha && (diff_mode == :single_commit || base_sha)
    end

    private

    def presence(value)
      return if value.nil?

      stripped = value.strip
      stripped.empty? ? nil : stripped
    end
  end

  class SpecChangeGuard
    Result = Struct.new(:success?, :message, :covered_paths, keyword_init: true)

    MONITORED_PREFIXES = %w[app/ lib/].freeze
    EXEMPT_PREFIXES = %w[app/assets/ lib/tasks/].freeze
    SPEC_PREFIX = 'spec/'

    def initialize(changed_files:, monitored_prefixes: MONITORED_PREFIXES, exempt_prefixes: EXEMPT_PREFIXES)
      @changed_files = Array(changed_files).map(&:to_s).reject(&:empty?).uniq.sort
      @monitored_prefixes = monitored_prefixes
      @exempt_prefixes = exempt_prefixes
    end

    def evaluate
      relevant_paths = changed_files.select { |path| monitored?(path) && !exempt?(path) }

      return success('No product code changes requiring spec updates were detected.') if relevant_paths.empty?
      return success('Spec updates detected alongside product code changes.', relevant_paths) if spec_changes?

      failure(relevant_paths)
    end

    private

    attr_reader :changed_files, :monitored_prefixes, :exempt_prefixes

    def monitored?(path)
      monitored_prefixes.any? { |prefix| path.start_with?(prefix) }
    end

    def exempt?(path)
      exempt_prefixes.any? { |prefix| path.start_with?(prefix) }
    end

    def spec_changes?
      changed_files.any? { |path| path.start_with?(SPEC_PREFIX) }
    end

    def success(message, covered_paths = [])
      Result.new(success?: true, message: message, covered_paths: covered_paths)
    end

    def failure(relevant_paths)
      lines = [
        'Product code changed without matching spec updates.',
        '',
        'Add or update files under spec/ when changing:',
        *relevant_paths.map { |path| "- #{path}" },
        '',
        'Static asset changes under app/assets/ and Rake tasks under lib/tasks/ are exempt.'
      ]

      Result.new(success?: false, message: lines.join("\n"), covered_paths: relevant_paths)
    end
  end

  class TopLevelControllerCoverageGuard
    Result = Struct.new(:success?, :message, :covered_paths, keyword_init: true)

    REQUEST_SYSTEM_PREFIXES = %w[spec/requests/ spec/system/].freeze
    TOP_LEVEL_CONTROLLER_PATTERN = %r{\Aapp/controllers/[^/]+_controller\.rb\z}
    ACTION_DEFINITION = /\Adef\s+([a-z_]\w*[!?=]?)(?:\s*\(|\z)/.freeze

    def initialize(changed_files:, before_reader:, after_reader:, request_system_prefixes: REQUEST_SYSTEM_PREFIXES)
      @changed_files = Array(changed_files).map(&:to_s).reject(&:empty?).uniq.sort
      @before_reader = before_reader
      @after_reader = after_reader
      @request_system_prefixes = request_system_prefixes
    end

    def evaluate
      additions = added_actions_by_controller

      return success("No new top-level controller actions requiring request/system coverage were detected.") if additions.empty?
      return success("Request or system spec updates detected for new top-level controller actions.", additions.keys) if request_or_system_changes?

      failure(additions)
    end

    private

    attr_reader :changed_files, :before_reader, :after_reader, :request_system_prefixes

    def added_actions_by_controller
      changed_files.each_with_object({}) do |path, result|
        next unless top_level_controller?(path)

        before_actions = public_actions(before_reader.call(path))
        after_actions = public_actions(after_reader.call(path))
        added_actions = (after_actions - before_actions).sort

        result[path] = added_actions if added_actions.any?
      end
    end

    def top_level_controller?(path)
      path.match?(TOP_LEVEL_CONTROLLER_PATTERN) && path != "app/controllers/application_controller.rb"
    end

    def request_or_system_changes?
      changed_files.any? do |path|
        request_system_prefixes.any? { |prefix| path.start_with?(prefix) }
      end
    end

    def public_actions(source)
      visibility = :public

      source.to_s.each_line.each_with_object([]) do |line, actions|
        code = line.sub(/#.*\z/, "").strip
        next if code.empty?

        case code
        when "private", "protected"
          visibility = code.to_sym
          next
        when "public"
          visibility = :public
          next
        end

        next unless visibility == :public

        match = code.match(ACTION_DEFINITION)
        actions << match[1] if match
      end.uniq
    end

    def success(message, covered_paths = [])
      Result.new(success?: true, message: message, covered_paths: covered_paths)
    end

    def failure(additions)
      lines = [
        "New top-level controller actions were added without matching request/system coverage.",
        "",
        "Add or update files under spec/requests/ or spec/system/ when introducing:",
        *additions.flat_map do |path, actions|
          actions.map { |action| "- #{path}: ##{action}" }
        end,
        "",
        "This guard only applies to new public actions in app/controllers/*. Existing action edits still follow the broader spec-change rule."
      ]

      Result.new(success?: false, message: lines.join("\n"), covered_paths: additions.keys)
    end
  end
end
