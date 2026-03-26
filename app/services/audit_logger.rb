class AuditLogger
  def self.log!(...)
    new(...).log!
  end

  def initialize(auditable:, action:, message:, admin: nil, property: nil, actor_label: nil, metadata: {})
    @auditable = auditable
    @action = action
    @message = message
    @admin = admin
    @property = property
    @actor_label = actor_label
    @metadata = metadata
  end

  def log!
    AuditLog.create!(
      auditable: auditable,
      property: property_for_log,
      admin: admin,
      actor_label: actor_label,
      action: action,
      message: message,
      metadata: metadata.presence,
      occurred_at: Time.current
    )
  end

  private

  attr_reader :auditable, :action, :message, :admin, :property, :actor_label, :metadata

  def property_for_log
    return property if property.present?
    return auditable if auditable.is_a?(Property)
    return auditable.property if auditable.respond_to?(:property)

    nil
  end
end
