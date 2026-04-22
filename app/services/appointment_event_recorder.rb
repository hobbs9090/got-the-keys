class AppointmentEventRecorder
  def initialize(appointment)
    @appointment = appointment
  end

  def record_change_events
    record_status_change if previous_changes.key?("status")
    record_reschedule if previous_changes.key?("scheduled_at")
    record_internal_notes_change if previous_changes.key?("internal_notes")
    record_customer_notes_change if previous_changes.key?("notes")
    record_visit_outcome_change if previous_changes.key?("visit_outcome")
  end

  private

  attr_reader :appointment

  delegate :appointment_events, :admin, :status, :updated_at, :previous_changes, to: :appointment

  def record_status_change
    from_status, to_status = previous_changes.fetch("status")

    appointment_events.create!(
      admin:,
      event_type: to_status,
      from_status:,
      to_status:,
      message: I18n.t(
        "ui.appointments.event_messages.status_changed",
        from_status: I18n.t("ui.appointments.statuses.#{from_status}", default: from_status.humanize.downcase),
        to_status: I18n.t("ui.appointments.statuses.#{to_status}", default: to_status.humanize.downcase)
      ),
      occurred_at: updated_at
    )
  end

  def record_reschedule
    from_time, to_time = previous_changes.fetch("scheduled_at")

    appointment_events.create!(
      admin:,
      event_type: "rescheduled",
      from_status: status,
      to_status: status,
      message: I18n.t(
        "ui.appointments.event_messages.moved",
        from_time: I18n.l(from_time, format: :long),
        to_time: I18n.l(to_time, format: :long)
      ),
      occurred_at: updated_at
    )
  end

  def record_internal_notes_change
    appointment_events.create!(
      admin:,
      event_type: "internal_note_added",
      from_status: status,
      to_status: status,
      message: I18n.t("ui.appointments.event_messages.internal_notes_updated"),
      occurred_at: updated_at
    )
  end

  def record_customer_notes_change
    appointment_events.create!(
      admin:,
      event_type: "customer_note_updated",
      from_status: status,
      to_status: status,
      message: I18n.t("ui.appointments.event_messages.customer_notes_updated"),
      occurred_at: updated_at
    )
  end

  def record_visit_outcome_change
    _from_outcome, to_outcome = previous_changes.fetch("visit_outcome")
    return if to_outcome.blank?

    appointment_events.create!(
      admin:,
      event_type: to_outcome,
      from_status: status,
      to_status: status,
      message: I18n.t(
        "ui.appointments.event_messages.visit_outcome_marked",
        outcome: I18n.t("ui.appointments.visit_outcomes.#{to_outcome}", default: to_outcome.to_s.tr("_", " ").downcase)
      ),
      occurred_at: updated_at
    )
  end
end
