require "rails_helper"

RSpec.describe Admin::CustomerDirectory do
  let(:property) { FactoryBot.create(:property) }

  describe "#grouped_customers" do
    it "returns one row per unique customer email across all entry types" do
      FactoryBot.create(:appointment, :pending, property:, customer_name: "Alex Buyer", customer_email: "alex@example.com", customer_phone: "07700 900001")
      FactoryBot.create(:user, first_name: "Jamie", last_name: "Buyer", email: "jamie@example.com", mobile_number: "07700 900002")

      results = described_class.new.grouped_customers
      emails = results.map(&:customer_email)

      expect(emails).to include("alex@example.com", "jamie@example.com")
    end

    it "filters by search query against email, name, and phone" do
      FactoryBot.create(:appointment, :pending, property:, customer_name: "Alex Buyer", customer_email: "alex@example.com", customer_phone: "07700 900001")
      FactoryBot.create(:appointment, :pending, property:, customer_name: "Taylor Stone", customer_email: "taylor@example.com", customer_phone: "07700 900002")

      results = described_class.new(query: "alex").grouped_customers
      expect(results.map(&:customer_email)).to eq(["alex@example.com"])
    end
  end
end
