module AppVersionHelper
  def public_app_version
    "v#{Rails.configuration.x.got_the_keys.version}"
  end

  def app_build_sha
    Rails.configuration.x.got_the_keys.build_sha.presence
  end

  def app_build_number
    Rails.configuration.x.got_the_keys.build_number.presence
  end

  def app_build_value(value)
    value.presence || t("ui.admin.qa.version_box.unavailable", default: "Not available")
  end

  def full_app_version
    build_metadata = [app_build_sha, app_build_number].filter_map(&:presence).join(".")

    build_metadata.present? ? "#{public_app_version}+#{build_metadata}" : public_app_version
  end
end
