require "rails_helper"

RSpec.describe "Admin enquiry management", type: :system do
  def sign_in_as(admin)
    visit admin_enquiries_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: "changeme123"
    click_button "Sign in"
    visit admin_enquiries_path
  end

  it "lets an admin triage a new lead from the inbox" do
    admin = FactoryBot.create(:admin, email: "triage-admin@gotthekeys.com", password: "changeme123", password_confirmation: "changeme123")
    enquiry = FactoryBot.create(:enquiry, customer_name: "Ravi Patel")

    sign_in_as(admin)

    expect(page).to have_text("Lead inbox")

    within(find("[data-testid='lead-row-#{enquiry.id}']")) do
      click_link "Ravi Patel"
    end

    select "Qualified", from: "enquiry_status"
    select admin.email, from: "enquiry_admin_id"
    fill_in "enquiry_internal_notes", with: "Strong lead after first phone call."
    click_button "Save lead"

    expect(page).to have_text("Lead updated.")
    expect(page).to have_text("Qualified")
    expect(page).to have_text("Strong lead after first phone call.")

    expect(enquiry.reload.status).to eq("qualified")
    expect(enquiry.admin).to eq(admin)
  end
end
