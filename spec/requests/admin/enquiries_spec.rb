require "rails_helper"

RSpec.describe "Admin enquiries", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "leads-admin@gotthekeys.com", password: "secret123", password_confirmation: "secret123") }
  let(:property) { FactoryBot.create(:property, address_line_1: "7 Oakbank Avenue") }

  before do
    sign_in admin
  end

  it "shows the lead inbox and supports filtering" do
    matching = FactoryBot.create(:enquiry, :contacted, property:, admin:, customer_name: "Priya Shah")
    FactoryBot.create(:enquiry, property:, customer_name: "Hidden Lead")

    get admin_enquiries_path, params: { status: "contacted", admin_id: admin.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(matching.customer_name)
    expect(response.body).not_to include("Hidden Lead")
    expect(response.body).to include(%(data-testid="lead-inbox-filters"))
  end

  it "updates assignment, status, and notes" do
    enquiry = FactoryBot.create(:enquiry, property:, customer_name: "Mina Khan")

    patch admin_enquiry_path(enquiry), params: {
      enquiry: {
        admin_id: admin.id,
        status: "qualified",
        internal_notes: "Strong lead and ready for follow-up."
      }
    }

    expect(response).to redirect_to(admin_enquiry_path(enquiry))
    expect(enquiry.reload.status).to eq("qualified")
    expect(enquiry.admin).to eq(admin)
    expect(enquiry.internal_notes).to include("Strong lead")
  end
end
