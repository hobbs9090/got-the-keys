require "rails_helper"

RSpec.describe "Devise entry pages", type: :request do
  it "renders the registration page" do
    get new_user_registration_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Register")
    expect(response.body).to include("English")
    expect(response.body).to include("Deutsch")
    expect(response.body).to include("Français")
    expect(response.body).to include("Italiano")
    expect(response.body).to include("中文")
  end

  it "renders the member sign-in page" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sign in")
  end

  it "renders the admin sign-in page" do
    get new_admin_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sign in as Administrator")
  end

  it "renders the forgot password page" do
    get new_user_password_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Forgot Password")
  end

  it "renders the resend unlock instructions page" do
    get new_user_unlock_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Resend unlock instructions")
  end
end
