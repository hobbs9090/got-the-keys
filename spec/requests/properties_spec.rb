require 'rails_helper'

describe "Properties" do
  include ActiveSupport::Testing::TimeHelpers

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

    it "parses comma-formatted price filters" do
      matching = FactoryBot.create(
        :property,
        user:,
        address_line_1: "Comma Filter House",
        asking_price: 650_000,
        sale_status: Property::SALE_STATUSES[:for_sale]
      )
      FactoryBot.create(
        :property,
        user:,
        address_line_1: "Outside Price Range",
        asking_price: 825_000,
        sale_status: Property::SALE_STATUSES[:for_sale]
      )

      get properties_path, params: {
        sale_status: Property::SALE_STATUSES[:for_sale],
        min_price: "600,000",
        max_price: "700,000"
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(matching.address_line_1)
      expect(response.body).not_to include("Outside Price Range")
      expect(response.body).to include(%(value="600,000"))
      expect(response.body).to include(%(value="700,000"))
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

    it "does not show the build year on property cards" do
      get properties_path

      document = Nokogiri::HTML(response.body)
      card = document.at_css(%([data-testid="property-card"]))

      expect(card.text).not_to include(property.year_built.to_s)
      expect(card.text).not_to include(I18n.t("ui.properties.facts.year_built"))
    end

    it "renders brochure download links on property cards when public PDFs are available" do
      document = FactoryBot.create(
        :property_document,
        property:,
        title: "Sales brochure",
        file_name: "request-user-brochure.pdf",
        category: "brochure",
        visibility: "public"
      )

      get properties_path

      page = Nokogiri::HTML(response.body)
      download_link = page.at_css(%([data-testid="property-card-document-download-#{property.id}-#{document.id}"]))

      expect(download_link).to be_present
      expect(download_link.text).to eq("Brochure")
      expect(download_link["href"]).to eq(download_property_property_document_path(property, document))
      expect(download_link["data-turbo"]).to eq("false")
      expect(download_link["download"]).to eq("request-user-brochure.pdf")
    end

    it "renders trust cues using the shared badge styling on property cards" do
      get properties_path

      document = Nokogiri::HTML(response.body)
      trust_badges = document.css(".property-card__trust-list .property-card__trust-badge")
      trust_text = trust_badges.map { |badge| badge.text.squish }
      trust_badge = trust_badges.first

      expect(trust_badge).to be_present
      expect(trust_badge["class"]).to include("badge")
      expect(trust_badge["class"]).to include("badge--success")
      expect(trust_text).not_to include("Brochure ready")
    end

    it "uses the two-column catalogue grid modifier on the main properties page" do
      get properties_path

      document = Nokogiri::HTML(response.body)
      grid = document.at_css("#properties")

      expect(grid).to be_present
      expect(grid["class"]).to include("property-grid")
      expect(grid["class"]).to include("property-grid--catalogue")
    end

    it "keeps the shared pagination controls outside the results panel card" do
      12.times do |index|
        FactoryBot.create(
          :property,
          user:,
          address_line_1: "Paginated Listing #{index + 2}",
          postcode: format("BR1 %<n>AA", n: index + 2)
        )
      end

      get properties_path

      document = Nokogiri::HTML(response.body)
      results_panel = document.at_css(".site-card.property-results-panel")

      expect(document.css(".property-results-stack > .property-results-pagination").count).to eq(2)
      expect(results_panel).to be_present
      expect(results_panel.at_css(".pagination")).not_to be_present
    end

    it "keeps the catalogue sidebar sticky as one stack on larger screens" do
      stylesheet = Rails.root.join("app/assets/stylesheets/theme.scss").read

      expect(stylesheet).to match(
        /\.property-catalogue__sidebar\s*\{[^}]*position:\s*sticky;[^}]*top:\s*6\.5rem;[^}]*max-height:\s*calc\(100vh - 7\.5rem\);[^}]*overflow-y:\s*auto;/m
      )
      expect(stylesheet).to match(
        /\.property-catalogue__filters\s*\{[^}]*background-color:\s*var\(--color-surface-raised\);/m
      )
    end

    it "omits the browse card, catalogue overview, recommended, and response-time labels from the catalogue page" do
      get properties_path

      document = Nokogiri::HTML(response.body)
      hero_meta = document.at_css(".page-hero__meta.property-catalogue-hero__meta")
      results_meta = document.at_css(".property-results-panel__meta")
      browse_card = document.at_css(".property-catalogue__browse")

      expect(browse_card).not_to be_present
      expect(hero_meta.at_css(".badge")).not_to be_present
      expect(results_meta).not_to be_present
      expect(response.body).not_to include(I18n.t("ui.properties.catalogue.browse_title"))
      expect(response.body).not_to include(AppSettings.primary_branch_profile.fetch(:response_time))
    end
  end

  describe "GET /properties/new" do
    it "prefills the seller-facing defaults for a new listing" do
      sign_in user

      get new_property_path

      document = Nokogiri::HTML(response.body)
      country_field = document.at_css('input[name="property[country]"]')
      listing_state_select = document.at_css('select[name="property[listing_state]"]')

      expect(response).to have_http_status(:ok)
      expect(country_field["value"]).to eq("United Kingdom")
      expect(listing_state_select.at_css('option[selected][value="draft"]')).to be_present
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
      expect(response.body).not_to include(I18n.t("ui.branch_profile.team_label"))
      expect(showcase.text).not_to include(I18n.t("ui.properties.listing_states.published"))
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

      document = Nokogiri::HTML(response.body)
      seller_workspace = document.at_css(%([data-testid="seller-listing-workspace"]))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-testid="seller-listing-workspace"))
      expect(response.body).to include("Manage photos")
      expect(response.body).to include("Manage documents")
      expect(response.body).to include(%(data-testid="property-documents-panel"))
      expect(seller_workspace.parent["class"]).to include("property-workspace--seller")
      expect(seller_workspace.parent["class"]).not_to include("property-layout")
    end

    it "does not show furnishing in the key facts for sale listings" do
      property.update!(sale_status: Property::SALE_STATUSES[:for_sale], furnishing: "Part furnished")

      get property_path(property)

      expect(response.body).not_to include(I18n.t("ui.properties.facts.furnishing"))
      expect(response.body).not_to include("Part furnished")
    end

    it "shows furnishing in the key facts for rental listings" do
      property.update!(sale_status: Property::SALE_STATUSES[:for_rent], furnishing: "Part furnished")

      get property_path(property)

      expect(response.body).to include(I18n.t("ui.properties.facts.furnishing"))
      expect(response.body).to include("Part furnished")
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

    it "renders a JPEG upload field for the main property image" do
      sign_in user

      get new_property_path

      document = Nokogiri::HTML(response.body)
      upload_field = document.at_css('input[type="file"][name="property[image_upload]"]')
      furnishing_field = document.at_css("[data-property-furnishing-field]")

      expect(response).to have_http_status(:ok)
      expect(upload_field).to be_present
      expect(upload_field["accept"]).to eq(".jpg,.jpeg,image/jpeg")
      expect(furnishing_field).to be_present
      expect(furnishing_field["hidden"]).to eq("")
    end

    it "hides rent-only fields for sale listings by default" do
      sign_in user

      get new_property_path

      document = Nokogiri::HTML(response.body)
      deposit_field = document.at_css("[data-property-rental-only-field] input[name='property[deposit_amount]']")
      pets_field = document.at_css("[data-property-rental-only-field] input[name='property[pets_allowed]']")
      lease_length_field = document.at_css("[data-property-lease-length-field]")

      expect(response).to have_http_status(:ok)
      expect(deposit_field.ancestors("[data-property-rental-only-field]").first["hidden"]).to eq("")
      expect(pets_field.ancestors("[data-property-rental-only-field]").first["hidden"]).to eq("")
      expect(lease_length_field["hidden"]).to be_nil
    end

    it "shows lease length for non-freehold sale listings" do
      sign_in user

      property.update!(sale_status: Property::SALE_STATUSES[:for_sale], tenure: "Leasehold")

      get edit_property_path(property)

      document = Nokogiri::HTML(response.body)
      lease_length_field = document.at_css("[data-property-lease-length-field]")

      expect(response).to have_http_status(:ok)
      expect(lease_length_field["hidden"]).to be_nil
    end

    it "renders the asking price field as comma-friendly numeric text input" do
      sign_in user

      get new_property_path

      document = Nokogiri::HTML(response.body)
      price_field = document.at_css('input[name="property[asking_price]"]')

      expect(response).to have_http_status(:ok)
      expect(price_field).to be_present
      expect(price_field["type"]).to eq("text")
      expect(price_field["inputmode"]).to eq("numeric")
      expect(price_field["pattern"]).to eq("[0-9,\\s]*")
      expect(price_field["maxlength"]).to eq("15")
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

  describe "GET /properties/mine" do
    it "requires a signed-in seller" do
      get mine_properties_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the signed-in seller their saved and in-progress listings only" do
      sign_in user
      draft_property = FactoryBot.create(:property, :draft, user:, address_line_1: "Draft Mews")
      review_property = FactoryBot.create(:property, :review_pending, user:, address_line_1: "Review Cottage")
      live_property = FactoryBot.create(:property, user:, address_line_1: "Live House")
      FactoryBot.create(:property, user: FactoryBot.create(:user), address_line_1: "Someone Else's Home")

      get mine_properties_path

      document = Nokogiri::HTML(response.body)
      cards = document.css(%([data-testid="owner-property-card"]))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Draft Mews")
      expect(response.body).to include("Review Cottage")
      expect(response.body).to include("Live House")
      expect(response.body).not_to include("Someone Else's Home")
      expect(cards.count).to be >= 3
      expect(response.body).to include(I18n.t("ui.properties.listing_states.draft"))
      expect(response.body).to include(I18n.t("ui.properties.listing_states.review_pending"))
      expect(response.body).to include(I18n.t("ui.properties.listing_states.published"))
      expect(response.body).to include(property_path(draft_property))
      expect(response.body).to include(edit_property_path(draft_property))
    end

    it "shows upcoming, previous, and cancelled appointments for the seller's properties" do
      sign_in user
      property = FactoryBot.create(:property, user:, address_line_1: "Appointment House")
      other_property = FactoryBot.create(:property, user: FactoryBot.create(:user), address_line_1: "Someone Else's Appointment House")

      upcoming_time = Time.zone.local(2026, 4, 10, 14, 0)
      previous_time = Time.zone.local(2026, 4, 7, 14, 0)
      cancelled_time = Time.zone.local(2026, 4, 11, 10, 0)

      FactoryBot.create(:appointment, property:, customer_name: "Upcoming Customer", customer_email: "upcoming@example.com", requested_time: upcoming_time, scheduled_at: upcoming_time, status: "confirmed", skip_slot_validation: true)
      FactoryBot.create(:appointment, property:, customer_name: "Previous Customer", customer_email: "previous@example.com", requested_time: previous_time, scheduled_at: previous_time, status: "completed", skip_slot_validation: true)
      FactoryBot.create(:appointment, property:, customer_name: "Cancelled Customer", customer_email: "cancelled@example.com", requested_time: cancelled_time, scheduled_at: cancelled_time, status: "cancelled", skip_slot_validation: true)
      FactoryBot.create(:appointment, property: other_property, customer_name: "Other Customer", customer_email: "other@example.com", requested_time: upcoming_time, scheduled_at: upcoming_time, status: "confirmed", skip_slot_validation: true)

      travel_to(Time.zone.local(2026, 4, 8, 12, 0)) do
        get mine_properties_path
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Upcoming")
      expect(response.body).to include("Previous")
      expect(response.body).to include("Cancelled")
      expect(response.body).to include("Upcoming Customer")
      expect(response.body).to include("Previous Customer")
      expect(response.body).to include("Cancelled Customer")
      expect(response.body).not_to include("Other Customer")
      expect(response.body).to include(I18n.t("ui.appointments.statuses.confirmed"))
      expect(response.body).to include(I18n.t("ui.appointments.statuses.completed"))
      expect(response.body).to include(I18n.t("ui.appointments.statuses.cancelled"))
    end

    it "shows saved properties separately from owned listings" do
      sign_in user
      saved_property = FactoryBot.create(:property, address_line_1: "Saved Lane")
      owned_property = FactoryBot.create(:property, user:, address_line_1: "Owned Lane")
      FactoryBot.create(:saved_property, user:, property: saved_property)

      get mine_properties_path

      document = Nokogiri::HTML(response.body)
      saved_cards = document.css(%([data-testid="saved-property-card"]))
      owner_cards = document.css(%([data-testid="owner-property-card"]))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Saved homes")
      expect(response.body).to include("Saved Lane")
      expect(response.body).to include("Owned Lane")
      expect(response.body).to include("Remove from saved list")
      expect(saved_cards.count).to eq(1)
      expect(owner_cards.count).to be >= 1
    end

    it "shows an empty state when the seller has not created any listings yet" do
      sign_in FactoryBot.create(:user)

      get mine_properties_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No saved listings yet")
      expect(response.body).to include(new_property_path)
    end
  end

  describe "POST /properties" do
    it "creates a property with an uploaded jpeg hero image" do
      sign_in user

      post properties_path, params: {
        property: property_attributes(
          image_upload: Rack::Test::UploadedFile.new(
            Rails.root.join("spec/fixtures/files/property-upload.jpeg"),
            "image/jpeg"
          )
        )
      }

      property = Property.order(:id).last

      expect(response).to redirect_to(property_path(property))
      expect(property.image_file_name).to match(%r{\A/uploads/property_images/#{property.id}/[0-9a-f]{32}\.jpeg\z})
      expect(Rails.root.join("tmp", "uploads", property.image_file_name.delete_prefix("/uploads/"))).to exist
    end

    it "accepts a comma-formatted asking price and stores it as an integer" do
      sign_in user

      post properties_path, params: {
        property: property_attributes(asking_price: "650,000")
      }

      property = Property.order(:id).last

      expect(response).to redirect_to(property_path(property))
      expect(property.asking_price).to eq(650_000)
    end

    it "clears rent-only fields for sale listings" do
      sign_in user

      post properties_path, params: {
        property: property_attributes(
          sale_status: Property::SALE_STATUSES[:for_sale],
          deposit_amount: 2_500,
          lease_length_years: 999,
          pets_allowed: true,
          tenure: "Freehold"
        )
      }

      property = Property.order(:id).last

      expect(response).to redirect_to(property_path(property))
      expect(property.deposit_amount).to be_nil
      expect(property.lease_length_years).to be_nil
      expect(property.pets_allowed).to be(false)
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

    it "uses the stacked panel layout on photo and floor-plan management pages" do
      sign_in user

      get property_photos_path(property)
      expect(response.body).to include(%(page-section page-section--stacked-panels))

      get property_floor_plans_path(property)
      expect(response.body).to include(%(page-section page-section--stacked-panels))
    end
  end

  describe "GET /properties/1.json" do
    it "should retrieve page" do
      get "/properties/#{property.id}.json"

      expect(response).to have_http_status(:ok)
    end
  end

end
