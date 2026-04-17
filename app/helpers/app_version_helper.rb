module AppVersionHelper
  def public_app_version
    "v#{version_config.version}"
  end

  def app_build_sha
    development_runtime_build_sha || version_config.build_sha.presence
  end

  def short_app_build_sha(length = 7)
    app_build_sha&.first(length)
  end

  def local_app_build?
    return development_runtime_local_build unless development_runtime_local_build.nil?

    version_config.local_build
  end

  def display_app_build_sha
    return if short_app_build_sha.blank?

    local_app_build? ? "#{short_app_build_sha} + local" : short_app_build_sha
  end

  def app_build_number
    version_config.build_number.presence
  end

  def app_deployed_at
    value = version_config.deployed_at.presence
    return if value.blank?

    timestamp = Time.zone.parse(value)
    timestamp ? "#{l(timestamp, format: :long)} #{timestamp.zone}" : value
  rescue ArgumentError, TypeError
    value
  end

  def app_runtime_environment
    components = []
    deploy_target = version_config.deploy_target.presence

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

  private

  def version_config
    Rails.configuration.x.got_the_keys
  end

  def development_runtime_build_sha
    return unless use_runtime_git_metadata?

    ReleaseBuildMetadata.current_revision(Rails.root)
  end

  def development_runtime_local_build
    return unless use_runtime_git_metadata?

    ReleaseBuildMetadata.workspace_dirty?(Rails.root)
  end

  def use_runtime_git_metadata?
    Rails.env.development? && version_config.build_number.blank?
  end
end
