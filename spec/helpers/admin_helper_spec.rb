require "rails_helper"

RSpec.describe AdminHelper, type: :helper do
  describe "#translated_demo_scenario_key" do
    it "uses the locale-specific scenario name when available" do
      I18n.with_locale(:de) do
        expect(helper.translated_demo_scenario_key("fully_booked_day")).to eq("Voll ausgebuchter Tag")
      end
    end

    it "uses a friendly label for the curated local catalogue" do
      expect(helper.translated_demo_scenario_key("custom_sevenoaks_westerham_catalogue")).to eq("Curated Sevenoaks and Westerham catalogue")
    end
  end

  describe "#admin_demo_confirmation_phrase" do
    it "uses the scenario key as the typed confirmation phrase" do
      expect(helper.admin_demo_confirmation_phrase(key: "qa_edge_cases")).to eq("qa_edge_cases")
    end
  end

  describe "#admin_demo_confirmation_pattern" do
    it "returns a safe exact-match pattern for the phrase" do
      expect(helper.admin_demo_confirmation_pattern("deal_progression")).to eq("deal_progression")
    end
  end

  describe "#admin_demo_value" do
    it "translates appointment status hashes" do
      I18n.with_locale(:fr) do
        value = helper.admin_demo_value(:appointment_statuses, { "confirmed" => 2, "pending" => 1 })

        expect(value).to eq("Confirmee: 2, En attente: 1")
      end
    end
  end

  describe "#admin_notification_status_label" do
    it "returns the translated notification status" do
      I18n.with_locale(:it) do
        expect(helper.admin_notification_status_label("failed")).to eq("Fallita")
      end
    end
  end
end
