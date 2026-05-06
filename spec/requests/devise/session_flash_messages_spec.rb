require "rails_helper"
require "nokogiri"

RSpec.describe "Devise session flash messages" do
  def flash_document
    Nokogiri::HTML.parse(response.body)
  end

  def flash_text
    flash_document.at_css("[data-testid='flash-stack']")&.text&.strip
  end

  def notice_flash
    flash_document.at_css("[data-testid='flash-notice']")
  end

  it "shows an admin-specific sign-in notice" do
    admin = FactoryBot.create(:admin, email: "flash-admin@gotthekeys.com", password: "changeme123", password_confirmation: "changeme123")

    post admin_session_path, params: { admin: { email: admin.email, password: "changeme123" } }

    expect(response).to redirect_to(admin_root_path)

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(flash_text).to include("Signed in successfully as Admin.")
    expect(notice_flash).to be_present
    expect(notice_flash["data-auto-dismiss-after"]).to eq("5000")
  end

  it "always redirects admins to the admin dashboard after sign-in" do
    admin = FactoryBot.create(:admin, email: "stored-admin@gotthekeys.com", password: "changeme123", password_confirmation: "changeme123")

    get admin_leads_path
    expect(response).to redirect_to(new_admin_session_path)

    post admin_session_path, params: { admin: { email: admin.email, password: "changeme123" } }

    expect(response).to redirect_to(admin_root_path)
  end

  it "keeps the generic member sign-in notice" do
    user = FactoryBot.create(:user, email: "flash-user@example.com", password: "changeme123", password_confirmation: "changeme123")

    post user_session_path, params: { user: { email: user.email, password: "changeme123" } }

    expect(response).to redirect_to(root_path)

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(flash_text).to include("Signed in successfully.")
    expect(notice_flash).to be_present
    expect(notice_flash["data-auto-dismiss-after"]).to eq("5000")
  end
end
