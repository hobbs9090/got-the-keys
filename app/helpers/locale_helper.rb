module LocaleHelper
  def language_switcher_label
    t("languages.label")
  end

  def current_language_label
    language_label(I18n.locale)
  end

  def language_label(locale_code)
    t("languages.names.#{locale_code}")
  end

  def language_options
    AppSettings.available_languages.map { |locale_code| [language_label(locale_code), locale_code] }
  end
end
