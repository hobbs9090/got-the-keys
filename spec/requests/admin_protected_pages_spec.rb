require "rails_helper"

RSpec.describe "Admin-protected pages", type: :request do
  let(:admin) { FactoryBot.create(:admin, email: "protected-admin@gotthekeys.com", password: "changeme123", password_confirmation: "changeme123") }
  let(:user) { FactoryBot.create(:user, first_name: "Taylor", last_name: "Stone", email: "taylor.stone@example.com") }

  describe "GET /members" do
    it "redirects guests to the admin sign-in page" do
      get "/members"

      expect(response).to redirect_to(new_admin_session_path)
    end

    it "renders the member directory for admins" do
      sign_in admin
      user

      get "/members"
      document = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.email)
      expect(document.at_css("h1")&.text).to include(I18n.t("members.sale_or_rental"))
    end
  end
  describe "GET /users/:id" do
    it "redirects guests to the admin sign-in page" do
      get user_path(user)

      expect(response).to redirect_to(new_admin_session_path)
    end

    it "renders the user profile for admins" do
      sign_in admin

      get user_path(user)
      document = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taylor Stone")
      expect(response.body).to include("taylor.stone@example.com")
      expect(document.at_css("h1")&.text&.strip).to eq("Taylor Stone")
    end
  end

  describe "GET /admin/enquiries" do
    it "redirects guests to the admin sign-in page" do
      get admin_enquiries_path

      expect(response).to redirect_to(new_admin_session_path)
    end

    it "renders the lead inbox for admins" do
      sign_in admin
      FactoryBot.create(:enquiry, customer_name: "Inbox Lead")

      get admin_enquiries_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Lead inbox")
      expect(response.body).to include("Inbox Lead")
    end
  end

  describe "GET /admin/sales" do
    it "redirects guests to the admin sign-in page" do
      get admin_sales_path

      expect(response).to redirect_to(new_admin_session_path)
    end
  end

  describe "GET /admin/rentals" do
    it "redirects guests to the admin sign-in page" do
      get admin_rentals_path

      expect(response).to redirect_to(new_admin_session_path)
    end
  end
end
