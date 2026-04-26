module Api
  module V1
    # Locale handling for the JSON API. See docs/api/v1-spec.md §8.3.
    #
    # Resolution order:
    #   1. Accept-Language header (first parseable tag in the user's allow-list)
    #   2. current_user.language
    #   3. I18n.default_locale
    module Localized
      extend ActiveSupport::Concern

      included do
        before_action :set_api_locale
      end

      private

      def set_api_locale
        I18n.locale = pick_locale
      end

      def pick_locale
        candidates = []
        candidates.concat(parse_accept_language(request.headers["Accept-Language"]))
        candidates << current_user&.language
        candidates << I18n.default_locale

        candidates.each do |candidate|
          next if candidate.blank?
          tag = candidate.to_s.split("-").first.downcase
          return tag if AppSettings.available_languages.include?(tag)
        end

        I18n.default_locale
      end

      # Parses "fr-CH, fr;q=0.9, en;q=0.8" into ["fr", "fr", "en"].
      def parse_accept_language(header)
        return [] if header.blank?

        header.to_s.split(",").map do |chunk|
          tag, _q = chunk.strip.split(";", 2)
          tag.to_s.strip
        end.reject(&:empty?)
      end
    end
  end
end
