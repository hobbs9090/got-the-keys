require "rails_helper"

RSpec.describe AuditLog do
  describe "#actor_display" do
    it "prefers the admin email when present" do
      admin = FactoryBot.create(:admin, email: "admin@example.com")
      audit_log = described_class.new(
        admin:,
        actor_label: "Imported scenario",
        action: "demo_imported",
        message: "Imported demo data.",
        occurred_at: Time.current
      )

      expect(audit_log.actor_display).to eq("admin@example.com")
    end

    it "falls back to the actor label when no admin is present" do
      audit_log = described_class.new(
        actor_label: "Imported scenario",
        action: "demo_imported",
        message: "Imported demo data.",
        occurred_at: Time.current
      )

      expect(audit_log.actor_display).to eq("Imported scenario")
    end

    it "uses the translated system label as a final fallback" do
      audit_log = described_class.new(
        action: "demo_imported",
        message: "Imported demo data.",
        occurred_at: Time.current
      )

      expect(audit_log.actor_display).to eq(I18n.t("ui.common.system_actor", default: "System"))
    end
  end
end
