module AppVersionHelper
  def public_app_version
    "v#{Rails.configuration.x.got_the_keys.version}"
  end

  def app_build_sha
    Rails.configuration.x.got_the_keys.build_sha.presence
  end

  def short_app_build_sha(length = 7)
    app_build_sha&.first(length)
  end

  def local_app_build?
    Rails.configuration.x.got_the_keys.local_build
  end

  def display_app_build_sha
    return if short_app_build_sha.blank?

    local_app_build? ? "#{short_app_build_sha} + local" : short_app_build_sha
  end

  def app_build_number
    Rails.configuration.x.got_the_keys.build_number.presence
  end

  def app_deployed_at
    value = Rails.configuration.x.got_the_keys.deployed_at.presence
    return if value.blank?

    timestamp = Time.zone.parse(value)
    timestamp ? "#{l(timestamp, format: :long)} #{timestamp.zone}" : value
  rescue ArgumentError, TypeError
    value
  end

  def app_runtime_environment
    components = []
    deploy_target = Rails.configuration.x.got_the_keys.deploy_target.presence

    components << deploy_target if deploy_target.present?
    components << t("ui.admin.qa.version_box.rails_env", env: Rails.env, default: "Rails env %{env}")
    components.join(", ")
  end

  def app_build_value(value)
    value.presence || t("ui.admin.qa.version_box.unavailable", default: "Not available")
  end

  def full_app_version
    build_metadata = [app_build_sha, app_build_number].filter_map(&:presence).join(".")

    build_metadata.present? ? "#{public_app_version}+#{build_metadata}" : public_app_version
  end
end
