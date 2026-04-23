require "rails_helper"

RSpec.describe DeviseMailer, type: :mailer do
  describe "#reset_password_instructions" do
    it "renders the branded wordmark partial without raising" do
      user = FactoryBot.create(:user, email: "reset-password-user@example.com")

      mail = described_class.reset_password_instructions(user, "test-token")

      expect(mail.subject).to eq("Reset password instructions")
      expect(mail.body.encoded).to include("marketing-wordmark--mailer")
      expect(mail.body.encoded).to include("http://www.example.com/assets/gotthekeys-wordmark-green")
      expect(mail.body.encoded).to include("reset_password_token=test-token")
    end
  end
end
