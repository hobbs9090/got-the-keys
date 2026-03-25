module AppSettings
  module_function

  def available_languages
    Rails.configuration.x.got_the_keys.available_languages
  end

  def exchange_rate_gbp_to_cny
    Rails.configuration.x.got_the_keys.exchange_rate_gbp_to_cny
  end
end
