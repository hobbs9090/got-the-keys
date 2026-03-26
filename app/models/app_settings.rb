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
      name: "Sevenoaks and Westerham office",
      team_label: "Managed by the local GotTheKeys team",
      phone: "01732 650010",
      email: "hello@gotthekeys.com",
      response_time: "Usually replies within 1 business day",
      hours: "Mon-Sat, 9:00-18:00"
    }
  end
end
