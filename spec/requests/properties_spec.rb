require 'rails_helper'

describe "Properties" do
  let!(:user) { FactoryBot.create(:user, email: "request-user@example.com") }
  let!(:property) { FactoryBot.create(:property, user:) }

  describe "GET /properties" do
    it "should retrieve page" do
      get properties_path
      document = Nokogiri::HTML(response.body)
      footer_meta = document.at_css(".site-footer__small")
      footer_brand = document.at_css(".site-footer__brand span")

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(%r{favicon-house-[^"]+\.svg})
      expect(response.body).not_to include("favicon.ico")
      expect(footer_brand).to be_present
      expect(footer_brand.text.squish).to eq("© 2026 Steven Hobbs")
      expect(footer_meta).to be_present
      expect(footer_meta.at_css(%(a[href="#{cookie_policy_index_path(anchor: "cookie-preferences")}"]))).to be_present
      expect(footer_meta.at_css(%([data-testid="public-app-version"]))).to be_present
      expect(footer_meta.at_css(".site-footer__utility")&.text.to_s.squish).to eq("Cookie settings v#{Rails.configuration.x.got_the_keys.version}")
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
      document = Nokogiri::HTML(response.body)
      booking_panel = document.at_css(%([data-testid="booking-panel"]))
      enquiry_panel = document.at_css(%([data-testid="property-enquiry-panel"]))
      offer_panel = document.at_css(%([data-testid="property-offer-panel"]))
      branch_panel = document.at_css(%([data-testid="property-branch-card"]))

      expect(response).to have_http_status(:ok)
      expect(booking_panel).to be_present
      expect(enquiry_panel).to be_present
      expect(enquiry_panel["class"]).to include("empty-state")
      expect(enquiry_panel["class"]).to include("property-booking-panel__support-card")
      expect(offer_panel).to be_present
      expect(offer_panel["class"]).to include("empty-state")
      expect(offer_panel["class"]).to include("property-booking-panel__support-card")
      expect(branch_panel).to be_present
      expect(branch_panel["class"]).to include("empty-state")
      expect(branch_panel["class"]).to include("property-booking-panel__support-card")
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
      FactoryBot.create(:property_document, property:, title: "Sales brochure")

      get property_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-testid="seller-listing-workspace"))
      expect(response.body).to include("Manage photos")
      expect(response.body).to include("Manage documents")
      expect(response.body).to include(%(data-testid="property-documents-panel"))
    end
  end

  describe "GET /properties/new" do
    it "renders the seller listing form with spaced sections" do
      sign_in user

      get new_property_path

      document = Nokogiri::HTML(response.body)
      form = document.at_css(%([data-testid="property-listing-form"]))
      actions = form.at_css(".form-actions")

      expect(response).to have_http_status(:ok)
      expect(form).to be_present
      expect(form["class"]).to include("stacked-form")
      expect(form["class"]).to include("property-listing-form")
      expect(actions).to be_present
      expect(actions["class"]).to include("property-listing-form__actions")
      expect(document.at_css(%([data-testid="listing-workflow-panel"]))).to be_present
      expect(document.at_css(%([data-testid="listing-facts-panel"]))).to be_present
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
