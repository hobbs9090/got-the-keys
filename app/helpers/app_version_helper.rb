module AppVersionHelper
  def public_app_version
    "v#{Rails.configuration.x.got_the_keys.version}"
  end

  def full_app_version
    build_metadata = [
      Rails.configuration.x.got_the_keys.build_sha,
      Rails.configuration.x.got_the_keys.build_number
    ].filter_map(&:presence).join(".")

    build_metadata.present? ? "#{public_app_version}+#{build_metadata}" : public_app_version
  end
end
