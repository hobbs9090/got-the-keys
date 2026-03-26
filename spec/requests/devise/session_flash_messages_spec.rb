require "rails_helper"
require "nokogiri"

RSpec.describe "Devise session flash messages" do
  def flash_text
    Nokogiri::HTML.parse(response.body).at_css("[data-testid='flash-stack']")&.text&.strip
  end

  it "shows an admin-specific sign-in notice" do
    admin = FactoryBot.create(:admin, email: "flash-admin@gotthekeys.com", password: "changeme", password_confirmation: "changeme")

    post admin_session_path, params: { admin: { email: admin.email, password: "changeme" } }

    expect(response).to redirect_to(admin_root_path)

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(flash_text).to include("Signed in successfully as Admin.")
  end

  it "keeps the generic member sign-in notice" do
    user = FactoryBot.create(:user, email: "flash-user@example.com", password: "changeme", password_confirmation: "changeme")

    post user_session_path, params: { user: { email: user.email, password: "changeme" } }

    expect(response).to redirect_to(root_path)

    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(flash_text).to include("Signed in successfully.")
  end
end
