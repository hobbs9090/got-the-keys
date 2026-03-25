module CookiePolicyHelper
  def cookie_consent_status_label
    if cookie_consent_all?
      t("cookie_policy.current_status_all")
    elsif cookie_consent_essential_only?
      t("cookie_policy.current_status_essential")
    else
      t("cookie_policy.current_status_pending")
    end
  end

  def cookie_consent_status_badge_class
    if cookie_consent_all?
      "badge badge--success"
    elsif cookie_consent_essential_only?
      "badge badge--neutral"
    else
      "badge badge--warning"
    end
  end
end
