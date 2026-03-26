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
end
