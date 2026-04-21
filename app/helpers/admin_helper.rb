module AdminHelper
  def admin_two_factor_qr_svg(uri)
    svg_markup = RQRCode::QRCode.new(uri, level: :m).as_svg(
      color: "10213f",
      fill: "ffffff",
      module_size: 5,
      shape_rendering: "crispEdges",
      standalone: true,
      use_path: true,
      viewbox: true
    )

    svg_markup.sub(/\A<\?xml[^>]+>\s*/, "").html_safe
  end

  def admin_two_factor_mode_label(value)
    t("ui.admin.security.modes.#{value}", default: value.to_s.humanize)
  end

  def admin_two_factor_audit_action_label(action)
    t("ui.admin.security.audit_actions.#{action}", default: action.to_s.humanize)
  end

  def translated_demo_scenario_key(key)
    t("ui.admin.demo_data.scenario_keys.#{key}", default: key.to_s.humanize)
  end

  def admin_scenario_name_label(scenario)
    key = scenario[:key] || scenario["key"]
    translated_demo_scenario_key(key)
  end

  def admin_scenario_description_label(scenario)
    key = scenario[:key] || scenario["key"]
    fallback = scenario[:description] || scenario["description"]

    t("ui.admin.demo_data.scenario_descriptions.#{key}", default: fallback)
  end

  def admin_demo_confirmation_phrase(key_or_scenario)
    key = key_or_scenario.is_a?(Hash) ? key_or_scenario.fetch(:key) : key_or_scenario

    key.to_s
  end

  def admin_demo_confirmation_pattern(key_or_scenario)
    Regexp.escape(admin_demo_confirmation_phrase(key_or_scenario))
  end

  def admin_demo_action_label(action_type)
    t("ui.admin.demo_data.actions.#{action_type}", default: action_type.to_s.humanize)
  end

  def admin_demo_label(label)
    t(
      "ui.admin.demo_data.labels.#{label}",
      default: t(
        "ui.admin.demo_data.preview_labels.#{label}",
        default: label.to_s.humanize
      )
    )
  end

  def admin_demo_value(label, value)
    return value.join(", ") if value.is_a?(Array)
    return value unless value.is_a?(Hash)

    case label.to_sym
    when :appointment_statuses
      value.map do |status, count|
        "#{I18n.t("ui.appointments.statuses.#{status}", default: status.to_s.humanize)}: #{count}"
      end.join(", ")
    else
      value.map { |key, nested_value| "#{admin_demo_label(key)}: #{nested_value}" }.join(", ")
    end
  end

  def admin_notification_status_label(status)
    t("ui.admin.notification_logs.statuses.#{status}", default: status.to_s.humanize)
  end

  def admin_notification_badge_state(status)
    case status.to_s
    when "failed"
      "no_show"
    when "sent"
      "confirmed"
    else
      "pending"
    end
  end

  def admin_availability_window_kind_label(kind)
    t("ui.admin.properties.show.window_kinds.#{kind}", default: kind.to_s.humanize)
  end

  def admin_scenario_family_label(value)
    t("ui.admin.qa.scenario_families_labels.#{value}", default: value.to_s.tr("_", " ").humanize)
  end

  def admin_scenario_complexity_label(value)
    t("ui.admin.qa.scenario_complexities.#{value}", default: value.to_s.humanize)
  end

  def admin_scenario_risk_type_label(value)
    t("ui.admin.qa.scenario_risk_types.#{value}", default: value.to_s.humanize)
  end

  def admin_scenario_journey_label(scenario)
    key = scenario[:key] || scenario["key"]
    fallback = scenario.dig(:qa, :intended_journey) || scenario.dig("qa", "intended_journey")

    t("ui.admin.demo_data.scenario_journeys.#{key}", default: fallback)
  end

  def admin_scenario_trainer_notes(scenario)
    key = scenario[:key] || scenario["key"]
    fallback = Array(scenario.dig(:qa, :trainer_notes) || scenario.dig("qa", "trainer_notes"))

    notes = t("ui.admin.demo_data.scenario_trainer_notes.#{key}", default: fallback)
    notes.is_a?(Array) ? notes : Array(fallback)
  end

  def admin_scenario_expected_assertions(scenario)
    key = scenario[:key] || scenario["key"]
    fallback = Array(scenario.dig(:qa, :expected_assertions) || scenario.dig("qa", "expected_assertions"))

    assertions = t("ui.admin.demo_data.scenario_expected_assertions.#{key}", default: fallback)
    assertions.is_a?(Array) ? assertions : Array(fallback)
  end

  def admin_selector_surface_label(entry)
    key = entry[:key] || entry["key"]
    fallback = entry[:surface] || entry["surface"]

    t("ui.admin.qa.selectors_catalog.#{key}.surface", default: fallback)
  end

  def admin_selector_purpose_label(entry)
    key = entry[:key] || entry["key"]
    fallback = entry[:purpose] || entry["purpose"]

    t("ui.admin.qa.selectors_catalog.#{key}.purpose", default: fallback)
  end

  def admin_security_activity_message(audit_log)
    t(
      "ui.admin.security.activity_messages.#{audit_log.action}",
      default: audit_log.message,
      actor: audit_log.actor_display,
      from: admin_two_factor_mode_label(audit_log.metadata&.fetch("from", nil)),
      to: admin_two_factor_mode_label(audit_log.metadata&.fetch("to", nil)),
      mode: admin_two_factor_mode_label(audit_log.metadata&.fetch("global_mode", nil))
    )
  end

  def admin_customer_badges(customer)
    [
      customer_badge(customer.registered_user.to_i.positive?, :registered_user, "badge--neutral"),
      customer_badge(customer.seller.to_i.positive?, :seller, "badge--success"),
      customer_badge(customer.landlord.to_i.positive?, :landlord, "badge--accent"),
      customer_badge(customer.tenant.to_i.positive?, :tenant, "badge--warning"),
      customer_badge(customer.buyer.to_i.positive?, :buyer, "badge--muted")
    ].compact
  end

  private

  def customer_badge(show, key, css_class)
    return unless show

    {
      key: key,
      label: t("ui.admin.customers.index.badges.#{key}"),
      css_class: css_class
    }
  end
end
