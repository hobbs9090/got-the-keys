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
  let(:admin_user) { FactoryBot.create(:user, email: "admin-saved-search@example.com") }
  let(:admin) { FactoryBot.create(:admin, email: admin_user.email, password: "secret123", password_confirmation: "secret123") }

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

  it "drops price filters when a saved search has no listing type" do
    sign_in user

    expect do
      post saved_searches_path, params: {
        saved_search: {
          locale: "en",
          search_query: "family home",
          town_city: "Sevenoaks",
          min_price: "600,000",
          max_price: "700,000",
          alerts_enabled: "1",
          catalogue_scope: "searches"
        }
      }
    end.to change(SavedSearch, :count).by(1)

    saved = SavedSearch.last

    expect(saved.sale_status).to be_blank
    expect(saved.min_price).to be_nil
    expect(saved.max_price).to be_nil
    expect(response).to redirect_to(searches_path(q: "family home", town_city: "Sevenoaks"))
  end

  it "normalizes the town alias through the catalogue parser when saving filters" do
    sign_in user

    expect do
      post saved_searches_path, params: {
        saved_search: {
          locale: "en",
          search_query: "family home",
          town: "sevenoaks",
          min_bedrooms: 3,
          alerts_enabled: "1",
          catalogue_scope: "searches"
        }
      }
    end.to change(SavedSearch, :count).by(1)

    saved = SavedSearch.last
    expect(saved.town_city).to eq("Sevenoaks")
    expect(saved.min_bedrooms).to eq(3)
    expect(response).to redirect_to(searches_path(q: "family home", town_city: "Sevenoaks", min_bedrooms: 3))
  end

  it "stores the current catalogue filters for a signed-in admin mapped to a user email" do
    sign_in admin

    expect do
      post saved_searches_path, params: {
        saved_search: {
          locale: "en",
          sale_status: Property::SALE_STATUSES[:for_sale],
          search_query: "admin filter",
          town_city: "Sevenoaks",
          min_bedrooms: 2,
          min_price: "500,000",
          max_price: "750,000",
          sort: "recommended",
          alerts_enabled: "1"
        }
      }
    end.to change(SavedSearch, :count).by(1)

    saved = SavedSearch.last
    expect(saved.user_id).to eq(admin_user.id)
    expect(response).to redirect_to(
      properties_path(
        q: "admin filter",
        sale_status: Property::SALE_STATUSES[:for_sale],
        town_city: "Sevenoaks",
        min_bedrooms: 2,
        min_price: 500_000,
        max_price: 750_000,
        sort: "recommended"
      )
    )
  end

  it "creates a saved-search user record for admins without a matching user account" do
    unmapped_admin = FactoryBot.create(:admin, email: "orphan-admin@example.com", password: "secret123", password_confirmation: "secret123")
    sign_in unmapped_admin

    expect do
      post saved_searches_path, params: {
        saved_search: {
          locale: "en",
          sale_status: Property::SALE_STATUSES[:for_sale],
          search_query: "admin created user",
          town_city: "Sevenoaks",
          min_bedrooms: 2,
          min_price: "450,000",
          max_price: "700,000",
          sort: "recommended",
          alerts_enabled: "1"
        }
      }
    end.to change(SavedSearch, :count).by(1)
      .and change(User, :count).by(1)

    generated_user = User.find_by(email: unmapped_admin.email)
    expect(generated_user).to be_present
    expect(generated_user.admin_provisioned).to be(true)
    expect(generated_user.mobile_number).to be_nil
    expect(SavedSearch.last.user_id).to eq(generated_user.id)
    expect(response).to redirect_to(
      properties_path(
        q: "admin created user",
        sale_status: Property::SALE_STATUSES[:for_sale],
        town_city: "Sevenoaks",
        min_bedrooms: 2,
        min_price: 450_000,
        max_price: 700_000,
        sort: "recommended"
      )
    )
  end

  it "lets a signed-in user remove a saved search" do
    sign_in user
    search = FactoryBot.create(:saved_search, user:)

    expect do
      delete saved_search_path(search)
    end.to change(SavedSearch, :count).by(-1)

    expect(response).to redirect_to(for_sale_index_path(search.filter_params))
    expect(flash[:notice]).to eq(I18n.t("ui.saved_searches.destroyed"))
  end

  it "responds with Turbo Stream when removing from the admin saved filters panel" do
    turbo_admin = FactoryBot.create(:admin, email: "turbo-saved-search-admin@example.com", password: "secret123", password_confirmation: "secret123")
    sign_in turbo_admin
    owner_user = FactoryBot.create(:user, email: turbo_admin.email)
    search_to_remove = FactoryBot.create(:saved_search, user: owner_user, town_city: "Sevenoaks")
    FactoryBot.create(:saved_search, user: owner_user, town_city: "Tunbridge Wells")

    expect do
      delete saved_search_path(search_to_remove),
             params: { admin_saved_filter_removal: "1" },
             headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
    end.to change(SavedSearch, :count).by(-1)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expected_target = ActionView::RecordIdentifier.dom_id(search_to_remove, :admin_saved_filter)
    expect(response.body).to include(%(target="#{expected_target}"))
    expect(response.body).to include('action="remove"')
    expect(response.body).to include('action="update"')
    expect(response.body).to include("admin-saved-filters-count")
  end

  it "removes the whole saved filters panel via Turbo Stream when the last filter is deleted from admin" do
    turbo_admin = FactoryBot.create(:admin, email: "turbo-saved-search-last@example.com", password: "secret123", password_confirmation: "secret123")
    sign_in turbo_admin
    owner_user = FactoryBot.create(:user, email: turbo_admin.email)
    search = FactoryBot.create(:saved_search, user: owner_user)

    expect do
      delete saved_search_path(search),
             params: { admin_saved_filter_removal: "1" },
             headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }
    end.to change(SavedSearch, :count).by(-1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(target="admin-saved-filters-panel"))
  end

  it "redirects to the for-rent catalogue after create when catalogue_scope is for_rent" do
    sign_in user
    FactoryBot.create(:property, :for_rent, town_city: "Sevenoaks")

    expect do
      post saved_searches_path, params: {
        saved_search: {
          locale: "en",
          sale_status: Property::SALE_STATUSES[:for_rent],
          search_query: "garden",
          town_city: "Sevenoaks",
          min_bedrooms: 2,
          min_price: "1,500",
          max_price: "3,000",
          sort: "recommended",
          alerts_enabled: "1",
          catalogue_scope: "for_rent"
        }
      }
    end.to change(SavedSearch, :count).by(1)

    expect(response).to redirect_to(
      for_rent_index_path(
        q: "garden",
        sale_status: Property::SALE_STATUSES[:for_rent],
        town_city: "Sevenoaks",
        min_bedrooms: 2,
        min_price: 1500,
        max_price: 3000,
        sort: "recommended"
      )
    )
  end

  it "redirects to the for-sale catalogue after create when catalogue_scope is for_sale" do
    sign_in user
    FactoryBot.create(:property, town_city: "Guildford")

    expect do
      post saved_searches_path, params: {
        saved_search: {
          locale: "en",
          sale_status: Property::SALE_STATUSES[:for_sale],
          search_query: "cottage",
          town_city: "Guildford",
          min_bedrooms: 3,
          min_price: "400,000",
          max_price: "900,000",
          sort: "price_low",
          alerts_enabled: "1",
          catalogue_scope: "for_sale"
        }
      }
    end.to change(SavedSearch, :count).by(1)

    expect(response).to redirect_to(
      for_sale_index_path(
        q: "cottage",
        sale_status: Property::SALE_STATUSES[:for_sale],
        town_city: "Guildford",
        min_bedrooms: 3,
        min_price: 400_000,
        max_price: 900_000,
        sort: "price_low"
      )
    )
  end

  it "redirects to the search page after create when catalogue_scope is searches" do
    sign_in user
    FactoryBot.create(:property, town_city: "Reigate")

    expect do
      post saved_searches_path, params: {
        saved_search: {
          locale: "en",
          sale_status: Property::SALE_STATUSES[:for_sale],
          search_query: "terrace",
          town_city: "Reigate",
          min_bedrooms: 2,
          min_price: "500,000",
          max_price: "800,000",
          sort: "newest",
          alerts_enabled: "1",
          catalogue_scope: "searches"
        }
      }
    end.to change(SavedSearch, :count).by(1)

    expect(response).to redirect_to(
      searches_path(
        q: "terrace",
        sale_status: Property::SALE_STATUSES[:for_sale],
        town_city: "Reigate",
        min_bedrooms: 2,
        min_price: 500_000,
        max_price: 800_000,
        sort: "newest"
      )
    )
  end

  it "returns a guest to the filtered catalogue after sign in" do
    get properties_path(town_city: "Sevenoaks", min_bedrooms: 3)

    post user_session_path, params: {
      user: {
        email: user.email,
        password: "changeme123"
      }
    }

    expect(response).to redirect_to(properties_path(town_city: "Sevenoaks", min_bedrooms: 3))
  end

  it "returns a guest to the filtered catalogue after registration" do
    FactoryBot.create(:property, town_city: "Tunbridge Wells", bedrooms: 2)

    get properties_path(town_city: "Tunbridge Wells", min_bedrooms: 2)

    email = "new-catalogue-user-#{SecureRandom.hex(4)}@example.com"

    expect do
      post user_registration_path, params: {
        user: {
          first_name: "Casey",
          last_name: "Rivera",
          mobile_number: "07595123456",
          email:,
          password: "changeme123",
          password_confirmation: "changeme123",
          language: "en",
          terms_of_service: "1"
        }
      }
    end.to change(User, :count).by(1)

    expect(response).to redirect_to(properties_path(town_city: "Tunbridge Wells", min_bedrooms: 2))
  end
end
