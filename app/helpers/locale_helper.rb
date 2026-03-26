module LocaleHelper
  LANGUAGE_FLAG_ASSETS = {
    "en" => "gb.svg",
    "de" => "de.svg",
    "fr" => "fr.svg",
    "it" => "it.svg",
    "zh" => "cn.svg"
  }.freeze

  def language_switcher_label
    t("languages.label")
  end

  def current_language_label
    language_label(I18n.locale)
  end

  def current_language_code
    I18n.locale.to_s.upcase
  end

  def language_label(locale_code)
    t("languages.names.#{locale_code}")
  end

  def language_flag_asset(locale_code)
    LANGUAGE_FLAG_ASSETS.fetch(locale_code.to_s, LANGUAGE_FLAG_ASSETS.fetch("en"))
  end

  def current_language_flag_asset
    language_flag_asset(I18n.locale)
  end

  def language_menu_options
    AppSettings.available_languages.map do |locale_code|
      {
        code: locale_code,
        label: language_label(locale_code),
        flag_asset: language_flag_asset(locale_code)
      }
    end
  end

  def language_options
    AppSettings.available_languages.map { |locale_code| [language_label(locale_code), locale_code] }
  end
end
