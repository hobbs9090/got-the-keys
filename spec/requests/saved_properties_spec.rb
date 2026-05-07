require "rails_helper"

RSpec.describe "Saved properties", type: :request do
  let(:property) { FactoryBot.create(:property, address_line_1: "18 Cedar Road") }
  let(:owner) { property.user }
  let(:user) { FactoryBot.create(:user, email: "saved-property-user@example.com") }

  it "shows a sign-in prompt to guests on the property page" do
    get property_path(property)

    page = Nokogiri::HTML(response.body)
    save_panel = page.at_css(%([data-testid="property-save-panel"]))
    sign_in_link = page.at_css(%([data-testid="save-property-sign-in-link"]))

    expect(save_panel).to be_present
    expect(sign_in_link).to be_present
    expect(sign_in_link.text).to include("Sign in to save")
    expect(sign_in_link["class"]).to include("button primary expanded")
    expect(sign_in_link["href"]).to include("return_to=#{CGI.escape(property_path(property))}")
    expect(sign_in_link["href"]).to include("save_property_id=#{property.id}")
  end

  it "keeps the save-property sign-in page neutral for renters" do
    get new_user_session_path(return_to: property_path(property), save_property_id: property.id)
    page = Nokogiri::HTML(response.body)

    expect(response).to have_http_status(:ok)
    expect(page.at_css(%(label[for="user_email"])).text.squish).to eq("Email")
    expect(response.body).to include("Sign in to save this home")
    expect(response.body).to include("Save homes, return to your shortlist")
    expect(page.at_css(".auth-panel").text.squish).to include("Sign in to manage your saved homes, viewings, offers, and any listings you're working on.")
    expect(response.body).to include("Use your email and password to continue with your GotTheKeys account.")
    expect(response.body).not_to include("Pick up where you left off")
    expect(response.body).not_to include("manage your listings, confirm viewings")
    expect(response.body).not_to include("Your dashboard keeps your property details")
    expect(response.body).not_to include("seller dashboard")
  end

  it "does not show seller-dashboard copy when a renter follows Sign in to save from a listing" do
    get property_path(property)
    listing_page = Nokogiri::HTML(response.body)
    sign_in_href = listing_page.at_css(%([data-testid="save-property-sign-in-link"]))["href"]

    get sign_in_href

    sign_in_page = Nokogiri::HTML(response.body)
    auth_panel = sign_in_page.at_css(".auth-panel")
    form_card = sign_in_page.at_css(".auth-form-card")

    expect(response).to have_http_status(:ok)
    expect(auth_panel.at_css("h1").text.squish).to eq("Sign in to save this home")
    expect(auth_panel.text.squish).to include("Save homes, return to your shortlist")
    expect(form_card.at_css(".auth-form-card__intro").text.squish).to eq("Use your email and password to continue with your GotTheKeys account.")
    expect(sign_in_page.at_css(%(input[name="save_property_id"]))["value"]).to eq(property.id.to_s)
    expect(sign_in_page.at_css(%(input[name="return_to"]))["value"]).to eq(property_path(property))
    expect(response.body).not_to include("get back into your seller dashboard")
    expect(response.body).not_to include("manage your listings, confirm viewings")
    expect(response.body).not_to include("your seller dashboard")
  end

  it "shows a save button to signed-in visitors" do
    sign_in user

    get property_path(property)

    page = Nokogiri::HTML(response.body)
    save_panel = page.at_css(%([data-testid="property-save-panel"]))
    save_button = page.at_css(%([data-testid="save-property-button"]))

    expect(save_panel).to be_present
    expect(save_button).to be_present
    expect(save_button.text).to include("Save property")
    expect(save_button["class"]).to include("button primary expanded")
  end

  it "does not show a save button to the property owner" do
    sign_in owner

    get property_path(property)

    page = Nokogiri::HTML(response.body)

    expect(page.at_css(%([data-testid="save-property-button"]))).to be_nil
    expect(page.at_css(%([data-testid="save-property-sign-in-link"]))).to be_nil
  end

  it "lets a signed-in visitor save a property" do
    sign_in user

    expect do
      post property_saved_property_path(property)
    end.to change(SavedProperty, :count).by(1)

    expect(response).to redirect_to(property_path(property))
    expect(SavedProperty.last.user).to eq(user)
    expect(SavedProperty.last.property).to eq(property)
  end

  it "lets a signed-in visitor remove a saved property" do
    sign_in user
    FactoryBot.create(:saved_property, user:, property:)

    get property_path(property)

    page = Nokogiri::HTML(response.body)
    unsave_button = page.at_css(%([data-testid="unsave-property-button"]))

    expect(unsave_button).to be_present
    expect(unsave_button.text).to include("Remove from saved list")

    expect do
      delete property_saved_property_path(property)
    end.to change(SavedProperty, :count).by(-1)

    expect(response).to redirect_to(property_path(property))
  end

  it "removes a saved property card via turbo stream in the workspace" do
    sign_in user
    FactoryBot.create(:saved_property, user:, property:)

    expect do
      delete property_saved_property_path(property), headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
    end.to change(SavedProperty, :count).by(-1)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include(%(turbo-stream action="remove"))
    expect(response.body).to include(%(target="#{ActionView::RecordIdentifier.dom_id(property, :saved_property_card)}"))
  end

  it "prevents a property owner from saving their own listing" do
    sign_in owner

    expect do
      post property_saved_property_path(property)
    end.not_to change(SavedProperty, :count)

    expect(response).to redirect_to(property_path(property))
    expect(flash[:alert]).to eq(I18n.t("ui.saved_properties.owner_alert"))
  end

  it "returns to the property page and saves the listing after sign in from the save prompt" do
    expect do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "changeme123"
        },
        return_to: property_path(property),
        save_property_id: property.id
      }
    end.to change(SavedProperty, :count).by(1)

    expect(response).to redirect_to(property_path(property))
    expect(user.saved_listings).to include(property)
  end

  it "returns to the property page and saves the listing after first-time registration" do
    property

    expect do
      post user_registration_path, params: {
        user: {
          first_name: "New",
          last_name: "Customer",
          mobile_number: "07595 123456",
          language: "en",
          terms_of_service: "1",
          email: "new-saved-property-user@example.com",
          password: "changeme123",
          password_confirmation: "changeme123"
        },
        return_to: property_path(property),
        save_property_id: property.id
      }
    end.to change(SavedProperty, :count).by(1)
      .and change(User, :count).by(1)

    expect(response).to redirect_to(property_path(property))
    expect(User.order(:id).last.saved_listings).to include(property)
  end

  it "keeps the pending save through the sign-in to registration hop via session" do
    get new_user_session_path(return_to: property_path(property), save_property_id: property.id)
    get new_user_registration_path

    page = Nokogiri::HTML(response.body)
    return_to_value = page.at_css('input[name="return_to"]')&.[]("value")
    save_property_id_value = page.at_css('input[name="save_property_id"]')&.[]("value")

    expect(return_to_value).to eq(property_path(property))
    expect(save_property_id_value).to eq(property.id.to_s)

    expect do
      post user_registration_path, params: {
        user: {
          first_name: "Session",
          last_name: "Flow",
          mobile_number: "07595 123456",
          language: "en",
          terms_of_service: "1",
          email: "session-saved-property-user@example.com",
          password: "changeme123",
          password_confirmation: "changeme123"
        },
        return_to: return_to_value,
        save_property_id: save_property_id_value
      }
    end.to change(SavedProperty, :count).by(1)

    created_user = User.find_by(email: "session-saved-property-user@example.com")

    expect(response).to redirect_to(property_path(property))
    expect(created_user.saved_listings).to include(property)
  end

  it "returns to the property page and saves the listing after a password reset flow" do
    get new_user_session_path(return_to: property_path(property), save_property_id: property.id)
    get new_user_password_path

    page = Nokogiri::HTML(response.body)
    return_to_value = page.at_css('input[name="return_to"]')&.[]("value")
    save_property_id_value = page.at_css('input[name="save_property_id"]')&.[]("value")

    expect(return_to_value).to eq(property_path(property))
    expect(save_property_id_value).to eq(property.id.to_s)

    raw_token = user.send_reset_password_instructions

    put user_password_path, params: {
      user: {
        reset_password_token: raw_token,
        password: "newpassword1",
        password_confirmation: "newpassword1"
      },
      return_to: return_to_value,
      save_property_id: save_property_id_value
    }

    expect(response).to redirect_to(new_user_session_path(return_to: property_path(property), save_property_id: property.id))

    follow_redirect!

    sign_in_page = Nokogiri::HTML(response.body)
    sign_in_return_to = sign_in_page.at_css('input[name="return_to"]')&.[]("value")
    sign_in_save_property_id = sign_in_page.at_css('input[name="save_property_id"]')&.[]("value")

    expect(sign_in_return_to).to eq(property_path(property))
    expect(sign_in_save_property_id).to eq(property.id.to_s)

    expect do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "newpassword1"
        },
        return_to: sign_in_return_to,
        save_property_id: sign_in_save_property_id
      }
    end.to change(SavedProperty, :count).by(1)

    expect(response).to redirect_to(property_path(property))
    expect(user.reload.saved_listings).to include(property)
  end
end
