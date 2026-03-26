require "rails_helper"

RSpec.describe Admin::EnquiryInboxQuery do
  let(:admin) { FactoryBot.create(:admin) }
  let(:property) { FactoryBot.create(:property) }

  it "filters by status and assignment" do
    matching = FactoryBot.create(:enquiry, :contacted, property:, admin:)
    FactoryBot.create(:enquiry, property:, admin:)
    FactoryBot.create(:enquiry, :qualified, property:)

    results = described_class.new(params: { status: "contacted", admin_id: admin.id }).call

    expect(results).to contain_exactly(matching)
  end

  it "filters to flagged spam when requested" do
    spam = FactoryBot.create(:enquiry, :spam, property:)
    FactoryBot.create(:enquiry, property:)

    results = described_class.new(params: { spam_only: "true" }).call

    expect(results).to contain_exactly(spam)
  end
end
