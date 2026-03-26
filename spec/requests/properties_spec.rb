require 'rails_helper'

describe "Properties" do
  let!(:user) { FactoryBot.create(:user, email: "request-user@example.com") }
  let!(:property) { FactoryBot.create(:property, user:) }

  describe "GET /properties" do
    it "should retrieve page" do
      get properties_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(%r{favicon-house-[^"]+\.svg})
      expect(response.body).not_to include("favicon.ico")
      expect(response.body).to include(%(data-testid="public-app-version"))
      expect(response.body).to include("v#{Rails.configuration.x.got_the_keys.version}")
    end

    it "renders a full first page of 12 property cards" do
      12.times do |index|
        FactoryBot.create(
          :property,
          user:,
          address_line_1: "Request Street #{index + 2}",
          postcode: format("RG1 %<n>1AA", n: index + 2),
          listing_tagline: "Listing #{index + 2}"
        )
      end

      get properties_path

      expect(response).to have_http_status(:ok)
      expect(response.body.scan(%(data-testid="property-card")).count).to eq(12)
      expect(response.body).to include(%(href="/properties?page=2"))
    end

    it "applies catalogue filters to the listing results" do
      matching = FactoryBot.create(
        :property,
        user:,
        address_line_1: "Filtered House",
        town_city: "Sevenoaks",
        bedrooms: 4,
        asking_price: 650_000,
        sale_status: Property::SALE_STATUSES[:for_sale]
      )
      FactoryBot.create(
        :property,
        :for_rent,
        user:,
        address_line_1: "Excluded Rental",
        town_city: "Sevenoaks",
        bedrooms: 4,
        asking_price: 2_500
      )

      get properties_path, params: {
        sale_status: Property::SALE_STATUSES[:for_sale],
        town_city: "Sevenoaks",
        min_bedrooms: 4,
        min_price: 600_000
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(matching.address_line_1)
      expect(response.body).not_to include("Excluded Rental")
    end
  end

  describe "GET /properties/1" do
    it "should retrieve page" do
      get property_path(property)

      expect(response).to have_http_status(:ok)
    end

    it "hides draft listings from public visitors" do
      property.update!(listing_state: "draft")

      get property_path(property)

      expect(response).to redirect_to(properties_path)
    end

    it "shows the seller workspace to the listing owner" do
      sign_in user
      FactoryBot.create(:photo, property:, primary: true)
      FactoryBot.create(:floor_plan, property:)

      get property_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-testid="seller-listing-workspace"))
      expect(response.body).to include("Manage photos")
    end
  end

  describe "GET /properties/1/photos" do
    it "should retrieve page" do
      get property_photos_path(property)

      expect(response).to have_http_status(:ok)
    end

    it "lets the owner create a marketing photo" do
      sign_in user

      post property_photos_path(property), params: {
        photo: {
          image_filename: "front-elevation.jpg",
          caption: "Front elevation",
          position: 1,
          primary: true
        }
      }

      expect(response).to redirect_to(property_photos_path(property))
      expect(property.photos.order(:id).last.image_filename).to eq("front-elevation.jpg")
      expect(property.photos.order(:id).last).to be_primary
    end
  end

  describe "GET properties/1/floor_plans" do
    it "should retrieve page" do
      get property_floor_plans_path(property)

      expect(response).to have_http_status(:ok)
    end

    it "lets the owner create a floor plan" do
      sign_in user

      post property_floor_plans_path(property), params: {
        floor_plan: {
          floor_plans: "ground-floor.pdf",
          label: "Ground floor",
          position: 1
        }
      }

      expect(response).to redirect_to(property_floor_plans_path(property))
      expect(property.floor_plans.order(:id).last.label).to eq("Ground floor")
    end
  end

  describe "GET /properties" do
    it "does not render withdrawn or draft properties in the public catalogue" do
      hidden_property = FactoryBot.create(:property, :draft, user:, address_line_1: "Hidden Mews")
      hidden_property.update!(listing_state: "withdrawn")

      get properties_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Hidden Mews")
    end
  end

  describe "GET /location/1" do
    it "should retrieve page" do
      get location_path(property)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /properties/1.json" do
    it "should retrieve page" do
      get "/properties/#{property.id}.json"

      expect(response).to have_http_status(:ok)
    end
  end

end
