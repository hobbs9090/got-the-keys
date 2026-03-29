require 'rails_helper'

describe "Properties" do
  let!(:user) { FactoryBot.create(:user, email: "request-user@example.com") }
  let!(:property) { FactoryBot.create(:property, user:) }

  describe "GET /properties" do
    it "should retrieve page" do
      get properties_path
      document = Nokogiri::HTML(response.body)
      footer_copy = document.at_css(".site-footer__copy")
      footer_meta = document.at_css(".site-footer__small")
      footer_brand = document.at_css(".site-footer__brand span")

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(%r{favicon-house-[^"]+\.svg})
      expect(response.body).not_to include("favicon.ico")
      expect(footer_brand).to be_present
      expect(footer_brand.text.squish).to eq("© 2026 Steven Hobbs")
      expect(footer_copy).to be_present
      expect(footer_copy.text.squish).to eq("Modern property discovery, appointment booking, and deterministic QA scenarios in one server-rendered Rails application. Built for realistic demos, acceptance testing, and AI-driven browser automation training.")
      expect(footer_meta).to be_present
      expect(footer_meta.at_css(".site-footer__meta-copy")).not_to be_present
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

    it "shows image-backed listings first in the default catalogue order" do
      image_backed = FactoryBot.create(:property, user:, address_line_1: "Image Backed Place", featured: false)
      text_only = FactoryBot.create(:property, user:, address_line_1: "Text Only Place", featured: false)
      FactoryBot.create(:photo, property: image_backed, image_filename: "image-backed-place.jpg", primary: true, position: 1)

      image_backed.update_columns(updated_at: 2.days.ago)
      text_only.update_columns(updated_at: 1.day.ago)

      get properties_path

      document = Nokogiri::HTML(response.body)
      property_links = document.css('[data-testid^="property-card-link-"]').map { |link| link.text.strip }

      expect(property_links.index("Image Backed Place")).to be < property_links.index("Text Only Place")
    end

    it "renders the card price on its own row beneath the header block" do
      get properties_path

      document = Nokogiri::HTML(response.body)
      card = document.at_css(%([data-testid="property-card"]))

      expect(card.at_css(".property-card__header")).to be_present
      expect(card.at_css(".property-card__header .property-card__price")).not_to be_present
      expect(card.at_css(".property-card__body > .property-card__price[data-testid='property-card-price']")).to be_present
    end
  end

  describe "GET /properties/1" do
    it "should retrieve page" do
      get property_path(property)
      document = Nokogiri::HTML(response.body)
      showcase = document.at_css(%([data-testid="property-showcase"]))
      booking_panel = document.at_css(%([data-testid="booking-panel"]))
      enquiry_panel = document.at_css(%([data-testid="property-enquiry-panel"]))
      offer_panel = document.at_css(%([data-testid="property-offer-panel"]))
      branch_panel = document.at_css(%([data-testid="property-branch-card"]))

      expect(response).to have_http_status(:ok)
      expect(showcase.at_css(".property-hero__media--ratio-3-2")).to be_present
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
      expect(response.body).to include("Built")
      expect(response.body).to include(property.year_built.to_s)
      expect(response.body).to include("Last refurbished")
      expect(response.body).to include(property.refurbished_year.to_s)
    end

    it "keeps the property hero media on a non-stretched 3:2 frame in the stylesheet" do
      stylesheet = Rails.root.join("app/assets/stylesheets/theme.scss").read

      expect(stylesheet).to match(
        /\.property-hero__media\s*\{[^}]*align-self:\s*start;[^}]*width:\s*100%;/m
      )
      expect(stylesheet).to match(
        /\.property-hero__media--ratio-3-2\s*\{[^}]*aspect-ratio:\s*3 \/ 2;/m
      )
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

    it "renders localized seller listing form copy for the signed-in language" do
      user.update!(language: "de")
      sign_in user

      get new_property_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("ui.properties.editor.workflow_title", locale: :de))
      expect(response.body).to include(I18n.t("ui.properties.editor.fields.listing_state", locale: :de))
      expect(response.body).to include(I18n.t("ui.properties.editor.submit", locale: :de))
      expect(response.body).to include(I18n.t("ui.properties.editor.placeholders.listing_tagline", locale: :de))
    end
  end

  describe "GET /properties/1/photos" do
    it "should retrieve page" do
      get property_photos_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('role="content"')
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
      expect(response.body).not_to include('role="content"')
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
      expect(response.body).not_to include('role="content"')
      expect(response.body).to include(%(alt="Map showing the area around #{property.address_line_1}"))
    end
  end

  describe "viewing times pages" do
    before do
      sign_in user
    end

    it "renders the viewing times index without invalid ARIA roles" do
      get property_viewing_times_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('role="content"')
    end

    it "renders the new viewing time page without invalid ARIA roles" do
      get new_property_viewing_time_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('role="content"')
    end
  end

  describe "GET /properties/1.json" do
    it "should retrieve page" do
      get "/properties/#{property.id}.json"

      expect(response).to have_http_status(:ok)
    end
  end

end
