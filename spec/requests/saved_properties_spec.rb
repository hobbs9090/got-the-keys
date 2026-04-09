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

  it "prevents a property owner from saving their own listing" do
    sign_in owner

    expect do
      post property_saved_property_path(property)
    end.not_to change(SavedProperty, :count)

    expect(response).to redirect_to(property_path(property))
  end

  it "returns to the property page and saves the listing after sign in from the save prompt" do
    expect do
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "changeme"
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
          password: "changeme",
          password_confirmation: "changeme"
        },
        return_to: property_path(property),
        save_property_id: property.id
      }
    end.to change(SavedProperty, :count).by(1)
      .and change(User, :count).by(1)

    expect(response).to redirect_to(property_path(property))
    expect(User.order(:id).last.saved_listings).to include(property)
  end
end
