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
    value.to_s.tr("_", " ").humanize
  end
end
