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
      admins = Array(active_scenario_payload[:admins]).map { |entry| entry[:email] }
      users = Array(active_scenario_payload[:users]).map { |entry| entry[:email] }

      [
        (I18n.t("ui.admin.qa.seeded_personas.admins", list: admins.join(", ")) if admins.any?),
        (I18n.t("ui.admin.qa.seeded_personas.sellers", list: users.join(", ")) if users.any?)
      ].compact.join(" | ")
    end
  end
end
