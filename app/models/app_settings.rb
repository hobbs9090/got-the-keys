module AppSettings
  module_function

  def available_languages
    Rails.configuration.x.got_the_keys.available_languages
  end

  def exchange_rate_gbp_to_cny
    Rails.configuration.x.got_the_keys.exchange_rate_gbp_to_cny
  end

  def primary_branch_profile
    {
      name: I18n.t("ui.branch_profile.name"),
      team_label: I18n.t("ui.branch_profile.team_label"),
      phone: "01732 650010",
      email: "hello@gotthekeys.uk",
      response_time: I18n.t("ui.branch_profile.response_time"),
      hours: I18n.t("ui.branch_profile.hours")
    }
  end
end
