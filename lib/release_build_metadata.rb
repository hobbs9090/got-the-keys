require "json"
require "time"

module ReleaseBuildMetadata
  module_function

  def load(path)
    return {} unless path

    JSON.parse(File.read(path.to_s))
  rescue Errno::ENOENT, JSON::ParserError
    {}
  end

  def payload(previous_metadata: {}, current_revision: nil, requested_build_sha: nil, requested_build_number: nil, deployed_at: Time.now.utc.iso8601)
    {
      build_sha: normalize_build_sha(requested_build_sha, current_revision),
      build_number: next_build_number(previous_metadata, requested_build_number),
      deployed_at: present_string(deployed_at)
    }.reject { |_key, value| value.nil? }
  end

  def next_build_number(previous_metadata, requested_build_number)
    previous_value = integer_value(previous_metadata["build_number"] || previous_metadata[:build_number])
    requested_value = integer_value(requested_build_number)
    next_value = [requested_value, previous_value && previous_value + 1, 1].compact.max

    next_value.to_s
  end

  def normalize_build_sha(requested_build_sha, current_revision)
    present_string(requested_build_sha) || short_sha(current_revision)
  end

  def short_sha(revision)
    value = present_string(revision)
    value ? value[0, 7] : nil
  end

  def integer_value(value)
    string = present_string(value)
    return nil unless string&.match?(/\A\d+\z/)

    string.to_i
  end

  def present_string(value)
    string = value.to_s.strip
    string.empty? ? nil : string
  end
end
