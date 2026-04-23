require 'rails_helper'

describe "Properties" do
  include ActiveSupport::Testing::TimeHelpers

  let!(:user) { FactoryBot.create(:user, email: "request-user@example.com") }
  let!(:property) { FactoryBot.create(:property, user:) }
  let(:version_config) { Rails.configuration.x.got_the_keys }

  around do |example|
    original_values = {
      build_sha: version_config.build_sha,
      local_build: version_config.local_build
    }

    example.run
  ensure
    version_config.build_sha = original_values[:build_sha]
    version_config.local_build = original_values[:local_build]
  end

  describe "GET /properties" do
    it "should retrieve page" do
      version_config.build_sha = "fd481e9abcdef0"
      version_config.local_build = true

      sign_in user
      get properties_path
      document = Nokogiri::HTML(response.body)
      footer_copy = document.at_css(".site-footer__copy")
      footer_meta = document.at_css(".site-footer__small")
      footer_brand = document.at_css(".site-footer__brand span")

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(%r{favicon-house-[^"]+\.svg})
      expect(response.body).to include("favicon.ico")
      expect(document.at_css('meta[name="turbo-cache-control"]')["content"]).to eq("no-preview")
      expect(footer_brand).to be_present
      expect(footer_brand.text.squish).to eq("© 2026 Steven Hobbs")
      expect(footer_copy).to be_present
      expect(footer_copy.text.squish).to eq("Modern property discovery, appointment booking, and deterministic QA scenarios in one server-rendered Rails application. Built for realistic demos, acceptance testing, and AI-driven browser automation training.")
      expect(footer_meta).to be_present
      expect(footer_meta.at_css(".site-footer__meta-copy")).not_to be_present
      expect(footer_meta.at_css(%(a[href="#{cookie_policy_index_path(anchor: "cookie-preferences")}"]))).to be_present
      expect(footer_meta.at_css(%([data-testid="public-app-version"]))).to be_present
      expect(footer_meta.at_css(%([data-testid="public-build-commit"]))).to be_present
      expect(footer_meta.at_css(".site-footer__utility")&.text.to_s.squish).to eq("Cookie settings v#{Rails.configuration.x.got_the_keys.version} Commit fd481e9 + local")
      expect(response.body).to include("v#{Rails.configuration.x.got_the_keys.version}")
      expect(response.body).to include("Commit fd481e9 + local")
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

    it "renders the catalogue filter with stable testid anchors on all inputs" do
      get properties_path

      document = Nokogiri::HTML.parse(response.body)

      expect(document.at_css(%([data-testid="property-filter-form"]))).to be_present
      expect(document.at_css(%([data-testid="property-search-query"]))).to be_present
      expect(document.at_css(%([data-testid="property-filter-town-city"]))).to be_present
      expect(document.at_css(%([data-testid="property-filter-bedrooms"]))).to be_present
      expect(document.at_css(%([data-testid="property-filter-min-price"]))).to be_present
      expect(document.at_css(%([data-testid="property-filter-max-price"]))).to be_present
      expect(document.at_css(%([data-testid="property-filter-sort"]))).to be_present
      expect(document.at_css(%([data-testid="apply-property-filters"]))).to be_present
      expect(document.at_css(%([data-testid="property-filter-reset"]))).to be_present
    end

    it "renders the view-property link and empty-state testid anchors on property cards" do
      get properties_path

      document = Nokogiri::HTML.parse(response.body)
      card = document.at_css(%([data-testid="property-card"]))
      view_link = document.at_css(%([data-testid="property-card-view-#{property.id}"]))

      expect(card).to be_present
      expect(view_link).to be_present
      expect(view_link["href"]).to eq(property_path(property))
    end

    it "renders the catalogue empty state testid when no properties match" do
      property.update!(listing_state: "withdrawn")

      get properties_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-testid="property-catalogue-empty"))
    end

    it "renders the pagination testid wrapper when results span multiple pages" do
      12.times do |index|
        FactoryBot.create(
          :property,
          user:,
          address_line_1: "Pagination Test #{index + 2}",
          postcode: format("SE1 %<n>1AB", n: index + 2)
        )
      end

      get properties_path

      document = Nokogiri::HTML.parse(response.body)

      expect(document.at_css(%([data-testid="pagination"]))).to be_present
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
      option_values = listing_state_select.css("option").map { |o| o["value"] }.compact_blank
      expect(option_values).to eq(%w[draft review_pending])
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
      booking_shortcut_form = document.at_css(%([data-testid="property-booking-shortcut-form"]))
      booking_form = document.at_css(%([data-testid="appointment-form"]))
      booking_slot_picker = document.at_css(%([data-testid="requested-time-picker"]))
      booking_sign_in_link = document.at_css(%([data-testid="book-viewing-sign-in-link"]))
      enquiry_link = document.at_css(%([data-testid="open-enquiry-form"]))
      offer_link = document.at_css(%([data-testid="open-offer-form"]))
      sign_in_return_path = new_user_session_path(return_to: property_path(property, anchor: "booking-panel"))

      expect(response).to have_http_status(:ok)
      expect(showcase.at_css(".property-hero__media--ratio-3-2")).to be_present
      expect(booking_panel).to be_present
      expect(booking_shortcut_form).not_to be_present
      expect(booking_form).not_to be_present
      expect(booking_slot_picker).not_to be_present
      expect(booking_sign_in_link).to be_present
      expect(booking_sign_in_link["href"]).to eq(sign_in_return_path)
      expect(enquiry_panel).to be_present
      expect(enquiry_panel["class"]).to include("empty-state")
      expect(enquiry_panel["class"]).to include("property-booking-panel__support-card")
      expect(enquiry_link).to be_present
      expect(enquiry_link["href"]).to eq(sign_in_return_path)
      expect(offer_panel).to be_present
      expect(offer_panel["class"]).to include("empty-state")
      expect(offer_panel["class"]).to include("property-booking-panel__support-card")
      expect(offer_link).to be_present
      expect(offer_link["href"]).to eq(sign_in_return_path)
      expect(branch_panel).to be_present
      expect(branch_panel["class"]).to include("empty-state")
      expect(branch_panel["class"]).to include("property-booking-panel__support-card")
      expect(response.body).to include("Sign in or create an account")
      expect(response.body).to include("Built")
      expect(response.body).to include(property.year_built.to_s)
      expect(response.body).to include("Last refurbished")
      expect(response.body).to include(property.refurbished_year.to_s)
      expect(response.body).not_to include(I18n.t("ui.branch_profile.team_label"))
      expect(showcase.text).not_to include(I18n.t("ui.properties.listing_states.published"))
    end

    it "shows the booking form to signed-in users" do
      sign_in user

      get property_path(property)

      document = Nokogiri::HTML(response.body)
      booking_form = document.at_css(%([data-testid="appointment-form"]))
      booking_slot_picker = document.at_css(%([data-testid="requested-time-picker"]))

      expect(response).to have_http_status(:ok)
      expect(booking_form).to be_present
      expect(booking_form["action"]).to eq(property_appointments_path(property))
      expect(booking_slot_picker).to be_present
      expect(document.at_css(%([data-testid="book-viewing-sign-in-link"]))).not_to be_present
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
      pets_field = document.at_css("[data-property-pets-allowed-field] input[name='property[pets_allowed]']")
      lease_length_field = document.at_css("[data-property-lease-length-field]")

      expect(response).to have_http_status(:ok)
      expect(deposit_field.ancestors("[data-property-rental-only-field]").first["hidden"]).to eq("")
      expect(pets_field.ancestors("[data-property-pets-allowed-field]").first["hidden"]).to eq("")
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

    it "hides lease length when tenure is freehold" do
      sign_in user

      property.update!(sale_status: Property::SALE_STATUSES[:for_sale], tenure: "Freehold", lease_length_years: 200)

      get edit_property_path(property)

      document = Nokogiri::HTML(response.body)
      lease_length_field = document.at_css("[data-property-lease-length-field]")

      expect(response).to have_http_status(:ok)
      expect(lease_length_field["hidden"]).to eq("")
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

  describe "GET /properties/:id/edit" do
    it "renders seller workspace inside the listing panel after the form" do
      sign_in user

      get edit_property_path(property)

      document = Nokogiri::HTML(response.body)
      panel = document.at_css("section.page-section > article.property-panel")
      form = document.at_css(%([data-testid="property-listing-form"]))
      workspace = document.at_css(%([data-testid="seller-listing-workspace"]))

      expect(response).to have_http_status(:ok)
      expect(panel).to be_present
      expect(form).to be_present
      expect(workspace).to be_present
      expect(workspace.ancestors.map(&:name)).to include("form")
      actions = document.at_css(".property-listing-form__actions")
      expect(actions).to be_present
      expect(workspace.next_element).to eq(actions)
    end

    it "ignores seller attempts to set admin-only workflow fields" do
      sign_in user
      published = FactoryBot.create(
        :property,
        user:,
        address_line_1: "Published Cottage",
        listing_state: "published",
        sale_status: Property::SALE_STATUSES[:for_sale],
        featured: false
      )

      patch property_path(published), params: {
        property: property_attributes.merge(
          address_line_1: "Renamed Cottage",
          listing_state: "sold",
          sale_status: Property::SALE_STATUSES[:for_rent],
          featured: true
        )
      }

      expect(response).to redirect_to(property_path(published))
      published.reload
      expect(published.address_line_1).to eq("Renamed Cottage")
      expect(published.listing_state).to eq("published")
      expect(published.sale_status).to eq(Property::SALE_STATUSES[:for_sale])
      expect(published.featured).to be(false)
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
      expect(response.body).not_to include(I18n.t("ui.properties.listing_states.published"))
      expect(response.body).to include(property_path(draft_property))
      expect(response.body).to include(edit_property_path(draft_property))
      expect(document.at_css("h1")&.text&.strip).to eq(I18n.t("ui.properties.mine.title", default: "My listings"))
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
      expect(response.body).to include(property_path(property))
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
      expect(response.body).to include(property_path(saved_property))
      expect(response.body).to include(property_path(owned_property))
      expect(response.body).to include("Remove from saved list")
      expect(saved_cards.count).to eq(1)
      expect(owner_cards.count).to be >= 1
    end

    it "includes a saved searches workspace panel" do
      sign_in user

      get mine_properties_path

      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      expect(document.at_css(%([data-testid="workspace-saved-searches"]))).to be_present
      expect(response.body).to include(I18n.t("ui.properties.mine.saved_searches_title"))
    end

    it "lists saved searches in the workspace" do
      sign_in user
      FactoryBot.create(:saved_search, user:, town_city: "Tunbridge Wells")

      get mine_properties_path

      document = Nokogiri::HTML(response.body)
      expect(document.css(%([data-testid="saved-search-card"])).count).to eq(1)
    end

    it "shows upcoming, previous, and cancelled bookings for the signed-in customer" do
      sign_in user

      upcoming_property = FactoryBot.create(:property, address_line_1: "Upcoming Booking House")
      previous_property = FactoryBot.create(:property, :for_rent, address_line_1: "Previous Booking House")
      cancelled_property = FactoryBot.create(:property, address_line_1: "Cancelled Booking House")
      other_users_property = FactoryBot.create(:property, address_line_1: "Someone Else's Booking House")

      upcoming_time = Time.zone.local(2026, 4, 10, 14, 0)
      previous_time = Time.zone.local(2026, 4, 7, 14, 0)
      cancelled_time = Time.zone.local(2026, 4, 11, 10, 0)

      upcoming_appointment = FactoryBot.create(
        :appointment,
        property: upcoming_property,
        customer_name: user.full_name,
        customer_email: user.email.upcase,
        customer_phone: user.mobile_number,
        requested_time: upcoming_time,
        scheduled_at: upcoming_time,
        status: "confirmed",
        skip_slot_validation: true
      )
      previous_appointment = FactoryBot.create(
        :appointment,
        property: previous_property,
        customer_name: user.full_name,
        customer_email: user.email,
        customer_phone: user.mobile_number,
        requested_time: previous_time,
        scheduled_at: previous_time,
        status: "completed",
        skip_slot_validation: true
      )
      cancelled_appointment = FactoryBot.create(
        :appointment,
        property: cancelled_property,
        customer_name: user.full_name,
        customer_email: user.email,
        customer_phone: user.mobile_number,
        requested_time: cancelled_time,
        scheduled_at: cancelled_time,
        status: "cancelled",
        skip_slot_validation: true
      )
      FactoryBot.create(
        :appointment,
        property: other_users_property,
        customer_name: "Someone Else",
        customer_email: "someone@example.com",
        customer_phone: "+44 20 7946 0999",
        requested_time: upcoming_time,
        scheduled_at: upcoming_time,
        status: "confirmed",
        skip_slot_validation: true
      )

      travel_to(Time.zone.local(2026, 4, 8, 12, 0)) do
        get mine_properties_path
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your bookings")
      expect(response.body).to include("Upcoming Booking House")
      expect(response.body).to include("Previous Booking House")
      expect(response.body).to include("Cancelled Booking House")
      expect(response.body).not_to include("Someone Else's Booking House")
      expect(response.body).to include(property_path(upcoming_property))
      expect(response.body).to include(property_path(previous_property))
      expect(response.body).to include(property_path(cancelled_property))
      expect(response.body).to include(appointment_path(upcoming_appointment, token: upcoming_appointment.access_token))
      expect(response.body).to include(appointment_path(previous_appointment, token: previous_appointment.access_token))
      expect(response.body).to include(appointment_path(cancelled_appointment, token: cancelled_appointment.access_token))
      expect(response.body).to include("View booking")

      document = Nokogiri::HTML(response.body)
      upcoming_badge = document.at_css(%([data-testid="customer-booking-sale-status-#{upcoming_appointment.id}"]))
      previous_badge = document.at_css(%([data-testid="customer-booking-sale-status-#{previous_appointment.id}"]))

      expect(upcoming_badge).to be_present
      expect(upcoming_badge.text.strip).to eq("For Sale")
      expect(previous_badge).to be_present
      expect(previous_badge.text.strip).to eq("For Rent")
    end

    it "shows the signed-in customer's offers and rental applications with their current statuses" do
      sign_in user

      accepted_sale_property = FactoryBot.create(:property, address_line_1: "Accepted Sale House")
      rejected_sale_property = FactoryBot.create(:property, address_line_1: "Rejected Sale House")
      approved_rental_property = FactoryBot.create(:property, :for_rent, address_line_1: "Approved Rental House")
      rejected_rental_property = FactoryBot.create(:property, :for_rent, address_line_1: "Rejected Rental House")
      other_property = FactoryBot.create(:property, address_line_1: "Someone Else's Offer House")

      accepted_offer = FactoryBot.create(
        :offer,
        :accepted,
        property: accepted_sale_property,
        buyer_name: user.full_name,
        buyer_email: user.email.upcase,
        buyer_phone: user.mobile_number,
        amount: 625_000
      )
      rejected_offer = FactoryBot.create(
        :offer,
        :rejected,
        property: rejected_sale_property,
        buyer_name: user.full_name,
        buyer_email: user.email,
        buyer_phone: user.mobile_number,
        amount: 610_000
      )
      FactoryBot.create(
        :offer,
        property: other_property,
        buyer_name: "Someone Else",
        buyer_email: "someone@example.com"
      )

      approved_rental_application = FactoryBot.create(
        :rental_application,
        :approved,
        property: approved_rental_property,
        applicant_name: user.full_name,
        applicant_email: user.email.upcase,
        applicant_phone: user.mobile_number
      )
      rejected_rental_application = FactoryBot.create(
        :rental_application,
        :rejected,
        property: rejected_rental_property,
        applicant_name: user.full_name,
        applicant_email: user.email,
        applicant_phone: user.mobile_number
      )
      FactoryBot.create(
        :rental_application,
        property: FactoryBot.create(:property, :for_rent, address_line_1: "Someone Else's Rental House"),
        applicant_name: "Someone Else",
        applicant_email: "someone@example.com"
      )

      get mine_properties_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your offers")
      expect(response.body).to include("Accepted Sale House")
      expect(response.body).to include("Rejected Sale House")
      expect(response.body).not_to include("Someone Else's Offer House")
      expect(response.body).to include(I18n.t("ui.offers.statuses.accepted"))
      expect(response.body).to include(I18n.t("ui.offers.statuses.rejected"))
      expect(response.body).to include(property_path(accepted_sale_property))
      expect(response.body).to include(property_path(rejected_sale_property))
      expect(response.body).to include(ApplicationController.helpers.number_to_currency(accepted_offer.amount, unit: "£", precision: 0))
      expect(response.body).to include(ApplicationController.helpers.number_to_currency(rejected_offer.amount, unit: "£", precision: 0))
      expect(response.body).to include(withdraw_property_offer_path(accepted_sale_property, accepted_offer))
      expect(response.body).not_to include(withdraw_property_offer_path(rejected_sale_property, rejected_offer))

      expect(response.body).to include("Your rental applications")
      expect(response.body).to include("Approved Rental House")
      expect(response.body).to include("Rejected Rental House")
      expect(response.body).not_to include("Someone Else's Rental House")
      expect(response.body).to include(I18n.t("ui.rental_applications.statuses.approved"))
      expect(response.body).to include(I18n.t("ui.rental_applications.statuses.rejected"))
      expect(response.body).to include(property_path(approved_rental_property))
      expect(response.body).to include(property_path(rejected_rental_property))
      expect(response.body).to include(I18n.l(approved_rental_application.move_in_date, format: :long))
      expect(response.body).to include(I18n.l(rejected_rental_application.move_in_date, format: :long))
      expect(response.body).not_to include(withdraw_property_rental_application_path(approved_rental_property, approved_rental_application))
      expect(response.body).not_to include(withdraw_property_rental_application_path(rejected_rental_property, rejected_rental_application))

      document = Nokogiri::HTML(response.body)
      accepted_offer_badge = document.at_css(%([data-testid="customer-offer-sale-status-#{accepted_offer.id}"]))
      approved_rental_badge = document.at_css(%([data-testid="customer-rental-application-sale-status-#{approved_rental_application.id}"]))

      expect(accepted_offer_badge).to be_present
      expect(accepted_offer_badge.text.strip).to eq("For Sale")
      expect(approved_rental_badge).to be_present
      expect(approved_rental_badge.text.strip).to eq("For Rent")
    end

    it "shows a withdraw action for live rental applications only" do
      sign_in user

      withdrawable_property = FactoryBot.create(:property, :for_rent, address_line_1: "Withdrawable Rental House")
      received_application = FactoryBot.create(
        :rental_application,
        property: withdrawable_property,
        applicant_name: user.full_name,
        applicant_email: user.email,
        applicant_phone: user.mobile_number,
        status: "received"
      )
      referencing_application = FactoryBot.create(
        :rental_application,
        property: FactoryBot.create(:property, :for_rent, address_line_1: "Referencing Rental House"),
        applicant_name: user.full_name,
        applicant_email: user.email,
        applicant_phone: user.mobile_number,
        status: "referencing"
      )
      approved_application = FactoryBot.create(
        :rental_application,
        :approved,
        property: FactoryBot.create(:property, :for_rent, address_line_1: "Approved Rental Later House"),
        applicant_name: user.full_name,
        applicant_email: user.email,
        applicant_phone: user.mobile_number
      )

      get mine_properties_path

      expect(response.body).to include(withdraw_property_rental_application_path(withdrawable_property, received_application))
      expect(response.body).to include(withdraw_property_rental_application_path(referencing_application.property, referencing_application))
      expect(response.body).not_to include(withdraw_property_rental_application_path(approved_application.property, approved_application))
    end

    it "lists upcoming customer bookings with the earliest scheduled visit first" do
      sign_in user

      later_property = FactoryBot.create(:property, address_line_1: "Later Visit Property")
      earlier_property = FactoryBot.create(:property, address_line_1: "Earlier Visit Property")

      later_time = Time.zone.local(2026, 4, 17, 11, 0)
      earlier_time = Time.zone.local(2026, 4, 15, 13, 0)

      FactoryBot.create(
        :appointment,
        property: later_property,
        customer_name: user.full_name,
        customer_email: user.email,
        customer_phone: user.mobile_number,
        requested_time: later_time,
        scheduled_at: later_time,
        status: "pending",
        skip_slot_validation: true
      )
      FactoryBot.create(
        :appointment,
        property: earlier_property,
        customer_name: user.full_name,
        customer_email: user.email,
        customer_phone: user.mobile_number,
        requested_time: earlier_time,
        scheduled_at: earlier_time,
        status: "pending",
        skip_slot_validation: true
      )

      travel_to(Time.zone.local(2026, 4, 8, 12, 0)) do
        get mine_properties_path
      end

      document = Nokogiri::HTML(response.body)
      panel = document.at_css(%([data-testid="customer-bookings-panel"]))
      expect(panel).to be_present

      upcoming_section = panel.css(".property-workspace-bookings__section").first
      rows = upcoming_section.css(%([data-testid="customer-booking-row"]))
      expect(rows.map { |row| row.at_css("strong")&.text&.strip }).to eq(
        ["Earlier Visit Property", "Later Visit Property"]
      )
      first_property_link = rows.first.at_css("strong a")
      expect(first_property_link).to be_present
      expect(first_property_link["href"]).to eq(property_path(earlier_property))
    end

    it "includes bookings that match the signed-in user's name and phone when the stored email is outdated" do
      sign_in user

      corrected_email_property = FactoryBot.create(:property, address_line_1: "Corrected Email Booking House")
      booked_time = Time.zone.local(2026, 4, 16, 15, 0)

      appointment = FactoryBot.create(
        :appointment,
        property: corrected_email_property,
        customer_name: user.full_name,
        customer_email: "outdated.email@example.net",
        customer_phone: user.mobile_number,
        requested_time: booked_time,
        scheduled_at: booked_time,
        status: "confirmed",
        skip_slot_validation: true
      )

      travel_to(Time.zone.local(2026, 4, 8, 12, 0)) do
        get mine_properties_path
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Corrected Email Booking House")
      expect(response.body).to include(appointment_path(appointment, token: appointment.access_token))
    end

    it "shows an empty state when the seller has not created any listings yet" do
      sign_in FactoryBot.create(:user)

      get mine_properties_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No listings yet")
      expect(response.body).to include(new_property_path)
    end

    it "renders empty state testid anchors on all workspace sections for a fresh user" do
      sign_in FactoryBot.create(:user)

      get mine_properties_path

      document = Nokogiri::HTML.parse(response.body)

      expect(document.at_css(%([data-testid="owner-listings-empty"]))).to be_present
      expect(document.at_css(%([data-testid="customer-bookings-empty"]))).to be_present
      expect(document.at_css(%([data-testid="customer-offers-empty"]))).to be_present
      expect(document.at_css(%([data-testid="customer-rental-applications-empty"]))).to be_present
      expect(document.at_css(%([data-testid="saved-homes-empty"]))).to be_present
      expect(document.at_css(%([data-testid="saved-searches-empty"]))).to be_present
    end

    it "always renders listings, bookings, offers, rental applications, saved homes, and saved searches sections when listings are empty" do
      sign_in FactoryBot.create(:user)

      get mine_properties_path

      document = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:ok)
      expect(document.at_css(%([data-testid="owner-listings-section"]))).to be_present
      expect(document.at_css(%([data-testid="customer-bookings-section"]))).to be_present
      expect(document.at_css(%([data-testid="customer-offers-section"]))).to be_present
      expect(document.at_css(%([data-testid="customer-rental-applications-section"]))).to be_present
      expect(document.at_css(%([data-testid="saved-homes-section"]))).to be_present
      expect(document.at_css(%([data-testid="workspace-saved-searches"]))).to be_present
      expect(response.body).to include("No listings yet")
      expect(response.body).to include("No bookings yet")
      expect(response.body).to include("No offers yet")
      expect(response.body).to include("No rental applications yet")
      expect(response.body).to include("No saved homes yet")
      expect(response.body).to include("No saved searches yet")
    end

    it "always renders listings, bookings, offers, rental applications, saved homes, and saved searches sections when listings exist" do
      sign_in user
      FactoryBot.create(:property, user:, address_line_1: "Consistent Listings Card")

      get mine_properties_path

      document = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:ok)
      expect(document.at_css(%([data-testid="owner-listings-section"]))).to be_present
      expect(document.at_css(%([data-testid="customer-bookings-section"]))).to be_present
      expect(document.at_css(%([data-testid="customer-offers-section"]))).to be_present
      expect(document.at_css(%([data-testid="customer-rental-applications-section"]))).to be_present
      expect(document.at_css(%([data-testid="saved-homes-section"]))).to be_present
      expect(document.at_css(%([data-testid="workspace-saved-searches"]))).to be_present
      expect(document.css(%([data-testid="owner-property-card"])).count).to be >= 1
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

    it "includes the original listing image in current photos when not yet added as a photo record" do
      sign_in user
      property.update!(image_file_name: "/uploads/property_images/#{property.id}/legacy-listing-image.jpg")

      get property_photos_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("/uploads/property_images/#{property.id}/legacy-listing-image.jpg")
      expect(response.body).to include("Primary listing image")
      expect(response.body).to include(%(data-testid="property-listing-image-thumbnail"))
    end

    it "shows thumbnails for saved photo records in current photos" do
      sign_in user
      photo = property.photos.create!(
        image_filename: "/uploads/property_photos/#{property.id}/1/gallery-photo.jpg",
        caption: "Garden view",
        position: 2,
        primary: false
      )

      get property_photos_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(photo.image_filename)
      expect(response.body).to include(%(data-testid="property-photo-thumbnail-#{photo.id}"))
      expect(response.body).to include("Garden view")
    end

    it "uses radio buttons for the shared primary image selection" do
      sign_in user
      primary_photo = property.photos.create!(
        image_filename: "/uploads/property_photos/#{property.id}/1/primary-photo.jpg",
        caption: "Front elevation",
        position: 1,
        primary: true
      )
      secondary_photo = property.photos.create!(
        image_filename: "/uploads/property_photos/#{property.id}/2/secondary-photo.jpg",
        caption: "Kitchen",
        position: 2,
        primary: false
      )

      get property_photos_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="new-photo-primary-#{property.id}"))
      expect(response.body).to include(%(id="photo-#{primary_photo.id}-primary"))
      expect(response.body).to include(%(id="photo-#{secondary_photo.id}-primary"))
      expect(response.body).to include(%(type="radio"))
      expect(response.body).to include(%(data-primary-photo-radio="true"))
      expect(response.body).not_to include(%(type="checkbox" name="photo[primary]"))
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

    it "renders the floor plans page with stable testid anchors" do
      sign_in user
      floor_plan = FactoryBot.create(:floor_plan, property:, label: "Ground floor")

      get property_floor_plans_path(property)

      document = Nokogiri::HTML.parse(response.body)

      expect(document.at_css(%([data-testid="floor-plan-add-form"]))).to be_present
      expect(document.at_css(%([data-testid="floor-plan-file-input"]))).to be_present
      expect(document.at_css(%([data-testid="floor-plan-add-submit"]))).to be_present
      expect(document.at_css(%([data-testid="floor-plan-item-#{floor_plan.id}"]))).to be_present
      expect(document.at_css(%([data-testid="floor-plan-update-#{floor_plan.id}"]))).to be_present
      expect(document.at_css(%([data-testid="floor-plan-remove-#{floor_plan.id}"]))).to be_present
    end

    it "renders the empty state testid when no floor plans exist" do
      sign_in user

      get property_floor_plans_path(property)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-testid="floor-plans-empty"))
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

    it "lets the owner upload a floor plan file" do
      sign_in user

      post property_floor_plans_path(property), params: {
        floor_plan: {
          floor_plan_upload: Rack::Test::UploadedFile.new(
            Rails.root.join("spec/fixtures/files/property-upload.jpeg"),
            "image/jpeg"
          ),
          label: "Uploaded floor plan",
          position: 2
        }
      }

      floor_plan = property.floor_plans.order(:id).last

      expect(response).to redirect_to(property_floor_plans_path(property))
      expect(floor_plan.floor_plans).to match(%r{\A/uploads/property_floor_plans/#{property.id}/#{floor_plan.id}/[0-9a-f]{32}\.jpeg\z})
      expect(Rails.root.join("tmp", "uploads", floor_plan.floor_plans.delete_prefix("/uploads/"))).to exist
    end
  end

  describe "GET /properties/1/documents" do
    it "matches the stacked seller tools layout used by photos and floor plans" do
      sign_in user

      get property_property_documents_path(property)

      document = Nokogiri::HTML(response.body)
      stacked_section = document.at_css("section.page-section.page-section--stacked-panels")
      panels = stacked_section&.css("> article.property-panel")

      expect(response).to have_http_status(:ok)
      expect(stacked_section).to be_present
      expect(panels&.count).to eq(2)
      expect(response.body).to include("Add document")
      expect(response.body).to include("Manage documents")
      expect(response.body).to include(edit_property_path(property))
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
      document = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('role="content"')
      expect(response.body).to include(%(alt="Map showing the area around #{property.address_line_1}"))
      expect(document.at_css("h1")&.text&.strip).to include(property.address_line_1)
    end
  end

  describe "viewing times pages" do
    before do
      sign_in user
    end

    it "renders the viewing times index without invalid ARIA roles" do
      get property_viewing_times_path(property)
      document = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('role="content"')
      expect(document.at_css("h1")&.text&.strip).to include(property.address_line_1)
    end

    it "renders the viewing times page with stable testid anchors" do
      get property_viewing_times_path(property)

      document = Nokogiri::HTML.parse(response.body)

      expect(document.at_css(%([data-testid="viewing-times-list"]))).to be_present
      expect(document.at_css(%([data-testid="add-viewing-time-link"]))).to be_present
      expect(document.at_css(%([data-testid="add-viewing-time-link"]))["href"]).to eq(new_property_viewing_time_path(property))
    end

    it "renders the new viewing time page without invalid ARIA roles" do
      get new_property_viewing_time_path(property)
      document = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('role="content"')
      expect(document.at_css("h1")&.text&.strip).to include(property.address_line_1)
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
