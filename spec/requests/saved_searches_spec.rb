require "rails_helper"

RSpec.describe "Saved searches", type: :request do
  let!(:matching_property) do
    FactoryBot.create(
      :property,
      town_city: "Sevenoaks",
      bedrooms: 4,
      asking_price: 650_000,
      sale_status: Property::SALE_STATUSES[:for_sale]
    )
  end

  let(:user) { FactoryBot.create(:user) }

  it "redirects guests to sign in" do
    expect do
      post saved_searches_path, params: {
        saved_search: {
          locale: "en",
          sale_status: Property::SALE_STATUSES[:for_sale],
          search_query: "family home",
          town_city: "Sevenoaks",
          min_bedrooms: 3,
          min_price: "600,000",
          max_price: "700,000",
          sort: "recommended",
          alerts_enabled: "1"
        }
      }
    end.not_to change(SavedSearch, :count)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "stores the current catalogue filters for a signed-in user" do
    sign_in user

    expect do
      post saved_searches_path, params: {
        saved_search: {
          locale: "en",
          sale_status: Property::SALE_STATUSES[:for_sale],
          search_query: "family home",
          town_city: "Sevenoaks",
          min_bedrooms: 3,
          min_price: "600,000",
          max_price: "700,000",
          sort: "recommended",
          alerts_enabled: "1"
        }
      }
    end.to change(SavedSearch, :count).by(1)

    expect(response).to redirect_to(properties_path(q: "family home", sale_status: Property::SALE_STATUSES[:for_sale], town_city: "Sevenoaks", min_bedrooms: 3, min_price: 600_000, max_price: 700_000, sort: "recommended"))
    expect(flash[:notice]).to include("1 matching listing")
    saved = SavedSearch.last
    expect(saved.user_id).to eq(user.id)
    expect(saved.email).to eq(user.email)
    expect(saved.min_price).to eq(600_000)
    expect(saved.max_price).to eq(700_000)
    expect(matching_property).to be_present
  end

  it "lets a signed-in user remove a saved search" do
    sign_in user
    search = FactoryBot.create(:saved_search, user:)

    expect do
      delete saved_search_path(search)
    end.to change(SavedSearch, :count).by(-1)

    expect(response).to redirect_to(properties_path(search.filter_params))
    expect(flash[:notice]).to eq(I18n.t("ui.saved_searches.destroyed"))
  end

  it "returns a guest to the filtered catalogue after sign in" do
    get properties_path(town_city: "Sevenoaks", min_bedrooms: 3)

    post user_session_path, params: {
      user: {
        email: user.email,
        password: "changeme"
      }
    }

    expect(response).to redirect_to(properties_path(town_city: "Sevenoaks", min_bedrooms: 3))
  end

  it "returns a guest to the filtered catalogue after registration" do
    get properties_path(town_city: "Tunbridge Wells", min_bedrooms: 2)

    email = "new-catalogue-user-#{SecureRandom.hex(4)}@example.com"

    expect do
      post user_registration_path, params: {
        user: {
          first_name: "Casey",
          last_name: "Rivera",
          mobile_number: "07595123456",
          email:,
          password: "changeme",
          password_confirmation: "changeme",
          language: "en",
          terms_of_service: "1"
        }
      }
    end.to change(User, :count).by(1)

    expect(response).to redirect_to(properties_path(town_city: "Tunbridge Wells", min_bedrooms: 2))
  end
end
