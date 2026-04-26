# Long-lived, opaque refresh tokens for the JSON API. Rotated on every use.
#
# The plaintext token is only ever returned to the client at issue time; we
# store SHA-256 digests so a database leak does not yield usable tokens.
class ApiRefreshToken < ApplicationRecord
  REFRESH_TTL = 30.days
  TOKEN_BYTES = 32

  belongs_to :user

  validates :token_digest, :device_id, :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :revoked, -> { where.not(revoked_at: nil) }
  scope :for_device, ->(device_id) { where(device_id: device_id) }

  class << self
    # Issue a fresh token. Returns a tuple of [record, plaintext_token].
    def issue!(user:, device_id:, device_name: nil, user_agent: nil, ip_address: nil)
      raw   = SecureRandom.urlsafe_base64(TOKEN_BYTES)
      digest = digest_for(raw)
      record = create!(
        user:         user,
        token_digest: digest,
        device_id:    device_id,
        device_name:  device_name,
        user_agent:   user_agent,
        ip_address:   ip_address,
        expires_at:   REFRESH_TTL.from_now
      )
      [record, "rt_#{record.id}.#{raw}"]
    end

    # Look up a refresh token from the opaque presented value.
    def find_by_presented(presented)
      return nil if presented.blank?

      _prefix, id_segment, raw = presented.split(/[._]/, 3) if presented.start_with?("rt_")
      return nil if raw.blank? || id_segment.blank?

      record = active.find_by(id: id_segment)
      return nil if record.blank?

      ActiveSupport::SecurityUtils.secure_compare(record.token_digest, digest_for(raw)) ? record : nil
    end

    def digest_for(raw)
      Digest::SHA256.hexdigest(raw)
    end
  end

  def revoke!(reason: nil)
    return if revoked_at?

    update!(revoked_at: Time.current)
    Rails.logger.info(
      "[api_refresh_token] revoked id=#{id} user_id=#{user_id} device_id=#{device_id} reason=#{reason.inspect}"
    )
  end

  def active?
    revoked_at.nil? && expires_at.present? && expires_at > Time.current
  end

  def touch_used!(ip_address: nil, user_agent: nil)
    attrs = { last_used_at: Time.current }
    attrs[:ip_address] = ip_address if ip_address.present?
    attrs[:user_agent] = user_agent if user_agent.present?
    update_columns(**attrs, updated_at: Time.current)
  end
end
