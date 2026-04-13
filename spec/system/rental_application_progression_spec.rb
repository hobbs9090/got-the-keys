require "rails_helper"

RSpec.describe "Rental application progression", type: :system do
  def sign_in_as_user(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "changeme"
    click_button "Sign in"
  end

  def sign_in_as(admin)
    visit admin_rentals_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: "changeme"
    click_button "Sign in"
  end

  it "lets an applicant submit and an admin approve a rental application" do
    property = FactoryBot.create(:property, :for_rent, address_line_1: "4 Station Court")
    admin = FactoryBot.create(:admin, email: "lettings-board@gotthekeys.com", password: "changeme", password_confirmation: "changeme")
    applicant = FactoryBot.create(:user, email: "rental-applicant@example.com", password: "changeme", password_confirmation: "changeme")

    sign_in_as_user(applicant)

    visit property_path(property)
    click_link "Start rental application"

    within('[data-testid="property-rental-application-form"]') do
      fill_in "rental_application_applicant_name", with: "Ravi Patel"
      fill_in "rental_application_applicant_email", with: "ravi.patel@example.com"
      fill_in "rental_application_applicant_phone", with: "07700 905777"
      fill_in "rental_application_move_in_date", with: (Date.current + 21.days).iso8601
      check "rental_application_guarantor_required"
      fill_in "rental_application_affordability_notes", with: "Permanent employment and ready to provide referencing documents."
      fill_in "rental_application_notes", with: "Would like to move quickly if possible."
      click_button "Submit rental application"
    end

    application = RentalApplication.order(:created_at).last

    sign_in_as(admin)
    click_link "Ravi Patel"
    select I18n.t("ui.rental_applications.statuses.approved"), from: "rental_application_status"
    click_button "Save application"

    expect(page).to have_text("Rental application updated.")
    expect(application.reload.status).to eq("approved")
    expect(property.reload.listing_state).to eq("let_agreed")
  end
end
