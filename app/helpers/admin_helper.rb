module AdminHelper
  def translated_demo_scenario_key(key)
    t("ui.admin.demo_data.scenario_keys.#{key}", default: key.to_s.humanize)
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
