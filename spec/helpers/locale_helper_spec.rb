require "rails_helper"

RSpec.describe LocaleHelper, type: :helper do
  describe "#language_switcher_label" do
    it "uses the current locale translation" do
      I18n.with_locale(:de) do
        expect(helper.language_switcher_label).to eq("Sprache")
      end
    end
  end

  describe "#current_language_label" do
    it "returns the native label for the active locale" do
      I18n.with_locale(:fr) do
        expect(helper.current_language_label).to eq("Français")
      end
    end
  end

  describe "#current_language_code" do
    it "returns the active locale code in uppercase" do
      I18n.with_locale(:zh) do
        expect(helper.current_language_code).to eq("ZH")
      end
    end
  end

  describe "#language_options" do
    it "maps configured locale codes to display labels" do
      allow(AppSettings).to receive(:available_languages).and_return(%w[en de fr it zh])

      expect(helper.language_options).to eq(
        [
          ["English", "en"],
          ["Deutsch", "de"],
          ["Français", "fr"],
          ["Italiano", "it"],
          ["中文", "zh"]
        ]
      )
    end
  end

  describe "#language_menu_options" do
    it "includes labels and SVG flag assets for each configured locale" do
      allow(AppSettings).to receive(:available_languages).and_return(%w[en de fr it zh])

      expect(helper.language_menu_options).to eq(
        [
          { code: "en", label: "English", flag_asset: "gb.svg" },
          { code: "de", label: "Deutsch", flag_asset: "de.svg" },
          { code: "fr", label: "Français", flag_asset: "fr.svg" },
          { code: "it", label: "Italiano", flag_asset: "it.svg" },
          { code: "zh", label: "中文", flag_asset: "cn.svg" }
        ]
      )
    end
  end
end
