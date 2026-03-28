# frozen_string_literal: true

require "fileutils"
require "pathname"
require "psych"

module Ci
  class LocaleHealth
    BASE_LOCALE = "en"
    TARGET_LOCALES = %w[de fr it zh].freeze
    GENERATED_DIR = "config/locales/generated"

    def initialize(root: Dir.pwd, base_locale: BASE_LOCALE, target_locales: TARGET_LOCALES)
      @root = Pathname(root)
      @base_locale = base_locale
      @target_locales = target_locales
    end

    attr_reader :base_locale, :target_locales

    def missing_keys(include_generated: true)
      data = flattened_locale_data(include_generated:)
      base = data.fetch(base_locale, {})

      target_locales.each_with_object({}) do |locale, report|
        translations = data.fetch(locale, {})
        report[locale] = base.each_key.select { |key| missing_translation?(translations[key]) }.sort
      end
    end

    def inconsistent_interpolations(include_generated: true)
      data = flattened_locale_data(include_generated:)
      base = data.fetch(base_locale, {})

      target_locales.each_with_object({}) do |locale, report|
        translations = data.fetch(locale, {})
        mismatches =
          base.each_with_object([]) do |(key, base_value), result|
            localized_value = translations[key]
            next if missing_translation?(localized_value)
            next unless base_value.is_a?(String) && localized_value.is_a?(String)

            base_variables = interpolation_variables(base_value)
            localized_variables = interpolation_variables(localized_value)
            next if base_variables == localized_variables

            result << {
              key: key,
              expected: base_variables,
              actual: localized_variables
            }
          end

        report[locale] = mismatches
      end
    end

    def sync_generated!
      source_data = flattened_locale_data(include_generated: false)
      base = source_data.fetch(base_locale, {})

      target_locales.each_with_object({}) do |locale, summary|
        translations = source_data.fetch(locale, {})
        missing =
          base.each_with_object({}) do |(key, value), result|
            next unless missing_translation?(translations[key])

            result[key] = value
          end

        write_generated(locale, missing)
        summary[locale] = missing.keys.sort
      end
    end

    private

    attr_reader :root

    def locale_paths(include_generated:)
      paths = Dir.glob(root.join("config/locales/**/*.yml")).sort
      return paths if include_generated

      generated_prefix = root.join(GENERATED_DIR).to_s
      paths.reject { |path| path.start_with?(generated_prefix) }
    end

    def flattened_locale_data(include_generated:)
      merged = Hash.new { |hash, key| hash[key] = {} }

      locale_paths(include_generated:).each do |path|
        payload = Psych.load_file(path, aliases: true)
        next unless payload.is_a?(Hash)

        payload.each do |locale, tree|
          next unless tree.is_a?(Hash)

          merged[locale.to_s] = deep_merge(merged[locale.to_s], flatten_tree(tree))
        end
      end

      merged
    end

    def flatten_tree(tree, prefix = nil, output = {})
      tree.each do |key, value|
        path = [prefix, key.to_s].compact.join(".")

        if value.is_a?(Hash)
          flatten_tree(value, path, output)
        else
          output[path] = value
        end
      end

      output
    end

    def build_tree(flattened)
      flattened.each_with_object({}) do |(path, value), tree|
        cursor = tree
        segments = path.split(".")

        segments[0...-1].each do |segment|
          cursor[segment] ||= {}
          cursor = cursor[segment]
        end

        cursor[segments.last] = value
      end
    end

    def write_generated(locale, flattened)
      path = root.join(GENERATED_DIR, "#{locale}.yml")

      if flattened.empty?
        File.delete(path) if File.exist?(path)
        return
      end

      FileUtils.mkdir_p(path.dirname)
      tree = { locale => deep_sort(build_tree(flattened)) }
      File.write(path, Psych.dump(tree, line_width: -1))
    end

    def deep_merge(left, right)
      left.merge(right) do |_key, old_value, new_value|
        if old_value.is_a?(Hash) && new_value.is_a?(Hash)
          deep_merge(old_value, new_value)
        else
          new_value
        end
      end
    end

    def deep_sort(value)
      return value unless value.is_a?(Hash)

      value.keys.sort.each_with_object({}) do |key, result|
        result[key] = deep_sort(value[key])
      end
    end

    def interpolation_variables(value)
      value.to_s.scan(/%\{([^}]+)\}/).flatten.uniq.sort
    end

    def missing_translation?(value)
      return true if value.nil?
      return value.strip.empty? if value.is_a?(String)
      return value.empty? if value.respond_to?(:empty?)

      false
    end
  end
end
