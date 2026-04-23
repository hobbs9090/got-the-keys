module Qa
  class DiagnosticsSnapshot
    def initialize(catalog: DemoData::ScenarioCatalog.new)
      @catalog = catalog
    end

    def to_h
      {
        active_scenario: active_scenario_name,
        build_version: ApplicationController.helpers.full_app_version,
        git_sha: ApplicationController.helpers.app_build_value(ApplicationController.helpers.app_build_sha),
        build_number: ApplicationController.helpers.app_build_value(ApplicationController.helpers.app_build_number),
        environment: ApplicationController.helpers.app_runtime_environment,
        mail_delivery_mode: ActionMailer::Base.delivery_method.to_s,
        job_adapter: ActiveJob::Base.queue_adapter.class.name.demodulize.underscore,
        seeded_personas: seeded_personas
      }
    end

    private

    attr_reader :catalog

    def active_scenario_payload
      @active_scenario_payload ||= catalog.fetch!(BookingConfiguration.current.active_demo_scenario_key).deep_symbolize_keys
    rescue KeyError
      {}
    end

    def active_scenario_name
      translated_scenario_key(BookingConfiguration.current.active_demo_scenario_key)
    end

    def translated_scenario_key(key)
      I18n.t("ui.admin.demo_data.scenario_keys.#{key}", default: key.to_s.humanize)
    end

    def seeded_personas
      admins = credential_lines(Array(active_scenario_payload[:admins]))
      users = Array(active_scenario_payload[:users])
      persisted_users = seeded_users_by_email(users)
      sellers, buyers = users.partition do |entry|
        persisted_users.fetch(normalized_email(entry[:email]), nil)&.properties_count.to_i.positive?
      end

      {
        admins: admins,
        sellers: user_credential_lines(sellers, persisted_users),
        buyers: user_credential_lines(buyers, persisted_users)
      }
    end

    def credential_lines(entries)
      entries.filter_map do |entry|
        email = entry[:email].to_s.strip
        password = entry[:password].to_s.strip
        next if email.blank?

        password.present? ? "#{email} / #{password}" : email
      end
    end

    def user_credential_lines(entries, persisted_users)
      entries.filter_map do |entry|
        email = entry[:email].to_s.strip
        password = entry[:password].to_s.strip
        next if email.blank?

        persisted_user = persisted_users.fetch(normalized_email(email), nil)
        first_name = persisted_user&.first_name.presence || entry[:first_name].to_s.strip
        last_name = persisted_user&.last_name.presence || entry[:last_name].to_s.strip
        language = persisted_user&.language.presence || entry[:language].to_s.strip
        full_name = [first_name, last_name].reject(&:blank?).join(" ")
        language_label = language.present? ? I18n.t("languages.names.#{language}", default: language) : nil

        summary = [full_name.presence, language_label.present? && "(#{language_label})"].compact.join(" ")
        credential = password.present? ? "#{email} / #{password}" : email

        [summary.presence, credential].compact.join(" - ")
      end
    end

    def seeded_users_by_email(entries)
      emails = entries.filter_map do |entry|
        normalized_email(entry[:email]).presence
      end

      User.where("lower(email) IN (?)", emails).index_by { |user| normalized_email(user.email) }
    end

    def normalized_email(email)
      email.to_s.strip.downcase
    end
  end
end
