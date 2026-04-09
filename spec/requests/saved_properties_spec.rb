require "rails_helper"

RSpec.describe "Saved properties", type: :request do
  let(:property) { FactoryBot.create(:property, address_line_1: "18 Cedar Road") }
  let(:owner) { property.user }
  let(:user) { FactoryBot.create(:user, email: "saved-property-user@example.com") }

  it "shows a sign-in prompt to guests on the property page" do
    get property_path(property)

    page = Nokogiri::HTML(response.body)
    sign_in_link = page.at_css(%([data-testid="save-property-sign-in-link"]))

    expect(sign_in_link).to be_present
    expect(sign_in_link.text).to include("Sign in to save")
  end

  it "shows a save button to signed-in visitors" do
    sign_in user

    get property_path(property)

    page = Nokogiri::HTML(response.body)
    save_button = page.at_css(%([data-testid="save-property-button"]))

    expect(save_button).to be_present
    expect(save_button.text).to include("Save property")
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
end
