require "rails_helper"

RSpec.describe "JavaScript runtime", type: :system, js: true do
  def boot_runtime(path = root_path)
    visit path
    dismiss_cookie_banner
    wait_for_theme_runtime
  end

  def enable_theme_preference(value)
    boot_runtime
    store_theme_preference(value)
  end

  def dismiss_cookie_banner
    return unless page.has_button?("Reject non-essential", wait: 1)

    click_button "Reject non-essential"
    expect(page).to have_no_css(".cookie-banner", wait: 5)
  end

  def wait_for_theme_runtime
    expect(page).to have_css("html[data-theme-ready='true']", wait: 5)
  end

  def choose_theme_preference(label)
    value = label.downcase

    page.execute_script(<<~JS)
      const toggle = document.querySelector('[data-testid="theme-toggle"]');
      if (!toggle) return;

      const option = toggle.querySelector('[data-testid="theme-option-#{value}"]');
      if (option) option.click();
    JS

    expect(page).to have_css(%([data-testid="theme-option-#{value}"][aria-pressed="true"]), visible: :all, wait: 5)
  end

  def store_theme_preference(value)
    page.execute_script(<<~JS)
      window.localStorage.setItem("gotthekeys-theme-preference", #{value.to_json});
    JS
  end

  def update_shared_search_filter_state(value)
    page.evaluate_async_script(<<~JS, value)
      const desiredValue = arguments[0];
      const done = arguments[arguments.length - 1];
      const select = document.getElementById("sale_status");
      const minLabel = document.querySelector("label[for='min_price']");
      const maxLabel = document.querySelector("label[for='max_price']");
      const minInput = document.querySelector("[data-property-search-min-price-input]");
      const maxInput = document.querySelector("[data-property-search-max-price-input]");

      if (!select || !minLabel || !maxLabel || !minInput || !maxInput) {
        done(null);
        return;
      }

      const option = Array.from(select.options).find((candidate) => candidate.value === desiredValue);
      if (!option) {
        done({
          selectedValue: select.value,
          minLabel: minLabel.textContent.trim(),
          maxLabel: maxLabel.textContent.trim(),
          minPlaceholder: minInput.getAttribute("placeholder"),
          maxPlaceholder: maxInput.getAttribute("placeholder")
        });
        return;
      }

      option.selected = true;
      select.value = option.value;
      select.dispatchEvent(new window.Event("input", { bubbles: true }));
      select.dispatchEvent(new window.Event("change", { bubbles: true }));

      window.requestAnimationFrame(() => {
        window.requestAnimationFrame(() => {
          done({
            selectedValue: select.value,
            minLabel: minLabel.textContent.trim(),
            maxLabel: maxLabel.textContent.trim(),
            minPlaceholder: minInput.getAttribute("placeholder"),
            maxPlaceholder: maxInput.getAttribute("placeholder")
          });
        });
      });
    JS
  end

  def expect_theme_preference(label)
    value = label.downcase

    expect(page).to have_css(%([data-testid="theme-option-#{value}"].is-active[aria-pressed="true"]), visible: :all, wait: 5)
  end

  def sign_in_as_user(user, password: "changeme")
    visit new_user_session_path

    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button "Sign in"
  end

  def sign_in_as_admin(admin, password: "changeme")
    visit new_admin_session_path

    fill_in "admin_email", with: admin.email
    fill_in "admin_password", with: password
    click_button "Sign in"
  end

  def admin_user_search_styles
    page.evaluate_script(<<~JS)
      (() => {
        const label = document.querySelector('label[for="q"]');
        const input = document.querySelector('[data-testid="admin-users-search-input"]');
        const placeholderStyles = getComputedStyle(input, "::placeholder");

        return {
          theme: document.documentElement.dataset.theme,
          labelColor: getComputedStyle(label).color,
          inputColor: getComputedStyle(input).color,
          inputBackground: getComputedStyle(input).backgroundColor,
          placeholderColor: placeholderStyles.color
        };
      })();
    JS
  end

  def styles_for(script)
    page.evaluate_script(script)
  end

  it "boots the homepage carousel and shared modal end to end" do
    visit root_path

    expect(page).to have_css('[data-carousel-bullet][data-slide="0"][aria-current="true"]')
    expect(page).to have_css('[data-carousel-slide].is-active[aria-hidden="false"]', count: 1)
    expect(page).to have_css("[data-carousel-next]")
    expect(page).to have_css('[data-carousel-bullet][data-slide="1"][aria-current="true"]', wait: 7)

    page.execute_script("document.querySelector('[data-carousel-next]').click()")

    expect(page).to have_css('[data-carousel-bullet][data-slide="2"][aria-current="true"]')
    expect(page).to have_css('[data-carousel-slide].is-active[aria-hidden="false"]', count: 1)

    visit contact_us_path

    expect(page).to have_css('[data-modal-trigger="map-modal"][aria-controls="map-modal"][aria-expanded="false"][aria-haspopup="dialog"]')
    expect(page).to have_css("#map-modal[hidden][aria-hidden='true']", visible: false)

    click_button "View Map"

    expect(page).to have_css("#map-modal[aria-hidden='false']", visible: true)
    expect(page).to have_css("body.site-modal-open", visible: false)
    expect(page).to have_link("View Larger Map")
    expect(page).to have_css("#map-modal .site-modal__close:focus", wait: 5)

    find("body").send_keys(:tab)
    expect(page).to have_css("#map-modal a:focus", text: "View Larger Map", wait: 5)

    find("body").send_keys(:tab)
    expect(page).to have_css("#map-modal .site-modal__close:focus", wait: 5)

    find("body").send_keys(:escape)

    expect(page).to have_css("#map-modal[hidden][aria-hidden='true']", visible: false)
    expect(page).to have_no_css("body.site-modal-open", visible: false)
  end

  it "clears modal overlay state when navigating away from an open modal", js: true do
    visit contact_us_path

    click_button "View Map"

    expect(page).to have_css("#map-modal[aria-hidden='false']", visible: true)
    expect(page).to have_css("body.site-modal-open", visible: false)

    visit root_path

    expect(page).to have_current_path(root_path, wait: 5)
    expect(page).to have_no_css("body.site-modal-open", visible: false)
    expect(page).to have_no_css('[data-modal][aria-hidden="false"]', visible: false)
  end

  it "keeps the public header navigation working with Turbo visits" do
    visit contact_us_path

    click_button "View Map"

    expect(page).to have_css("#map-modal[aria-hidden='false']", visible: true)
    expect(page).to have_css("body.site-modal-open", visible: false)

    page.execute_script("document.querySelector('[data-testid=\"site-nav\"] a[href=\"/searches\"]').click()")

    expect(page).to have_current_path(searches_path, wait: 5)
    expect(page).to have_no_css("body.site-modal-open", visible: false)
    expect(page).to have_no_css('[data-modal][aria-hidden="false"]', visible: false)
    expect(page).to have_title("Search")

    page.execute_script("document.querySelector('[data-testid=\"home-link\"]').click()")

    expect(page).to have_current_path(root_path, wait: 5)
    expect(page).to have_no_css("body.site-modal-open", visible: false)
    expect(page).to have_no_css('[data-modal][aria-hidden="false"]', visible: false)
    expect(page).to have_title("GotTheKeys")
  end

  it "clears modal overlay state during navigation lifecycle events", js: true do
    visit contact_us_path

    click_button "View Map"

    expect(page).to have_css("#map-modal[aria-hidden='false']", visible: true)
    expect(page).to have_css("body.site-modal-open", visible: false)

    page.execute_script(<<~JS)
      document.dispatchEvent(new CustomEvent("turbo:before-render"));
    JS

    expect(page).to have_no_css("body.site-modal-open", visible: false)
    expect(page).to have_css("#map-modal[hidden][aria-hidden='true']", visible: false)
  end

  it "recovers from stale overlay state on page load", js: true do
    visit root_path

    page.execute_script(<<~JS)
      document.body.classList.add("site-modal-open");

      const staleModal = document.createElement("div");
      staleModal.dataset.modal = "stale";
      staleModal.hidden = false;
      staleModal.setAttribute("aria-hidden", "false");
      document.body.appendChild(staleModal);

      document.cookie = "gotthekeys_cookie_consent=essential; path=/";

      const staleBanner = document.createElement("section");
      staleBanner.className = "cookie-banner";
      document.body.appendChild(staleBanner);
    JS

    visit root_path

    expect(page).to have_no_css("body.site-modal-open", visible: false)
    expect(page).to have_no_css('[data-modal][aria-hidden="false"]', visible: false)
    expect(page).to have_no_css(".cookie-banner", wait: 5)
  end

  it "clears admin modal overlay state when navigating away from the security page", js: true do
    admin = FactoryBot.create(:admin, email: "overlay-admin@example.com", password: "changeme", password_confirmation: "changeme")
    sign_in_as_admin(admin)

    visit admin_security_path

    page.execute_script(<<~JS)
      const modal = document.createElement("div");
      modal.id = "synthetic-admin-modal";
      modal.dataset.modal = "synthetic-admin-modal";
      modal.textContent = "Synthetic admin modal";
      modal.style.display = "block";
      modal.style.width = "12rem";
      modal.style.height = "4rem";
      modal.hidden = false;
      modal.setAttribute("aria-hidden", "false");
      document.body.appendChild(modal);
      document.body.classList.add("site-modal-open");
    JS

    expect(page.evaluate_script(<<~JS)).to eq(true)
      (() => {
        const modal = document.querySelector("#synthetic-admin-modal");
        return Boolean(modal && modal.getAttribute("aria-hidden") === "false");
      })()
    JS
    expect(page.evaluate_script("document.body.classList.contains('site-modal-open')")).to eq(true)

    visit admin_root_path

    expect(page).to have_current_path(admin_root_path, wait: 5)
    expect(page).to have_no_css("body.site-modal-open", visible: false)
    expect(page).to have_no_css('[data-modal][aria-hidden="false"]', visible: false)
  end

  it "toggles the furnishing field based on the selected sale status" do
    admin = FactoryBot.create(:admin, email: "listing-admin@example.com", password: "changeme", password_confirmation: "changeme")
    owner = FactoryBot.create(:user)
    property = FactoryBot.create(
      :property,
      user: owner,
      tenure: "Leasehold",
      sale_status: Property::SALE_STATUSES[:for_sale]
    )

    sign_in_as_admin(admin)
    visit edit_admin_property_path(property)
    dismiss_cookie_banner

    expect(page).to have_css("[data-property-furnishing-field][hidden]", visible: false)
    expect(page).to have_css("[data-property-rental-only-field][hidden]", visible: false, count: 1)
    expect(page).to have_selector("[data-property-pets-allowed-field]", visible: :hidden)
    expect(page).to have_no_css("[data-property-lease-length-field][hidden]", visible: false)

    select "For Rent", from: "property_sale_status"

    expect(page).to have_no_css("[data-property-furnishing-field][hidden]", visible: false)
    expect(page.evaluate_script("document.getElementById('property_furnishing').disabled")).to be(false)
    expect(page).to have_no_css("[data-property-rental-only-field][hidden]", visible: false)
    expect(page.evaluate_script("document.getElementById('property_deposit_amount').disabled")).to be(false)
    expect(page).to have_selector("[data-property-pets-allowed-field]", visible: :visible)
    expect(page.evaluate_script("document.getElementById('property_pets_allowed').disabled")).to be(false)
    expect(page).to have_no_css("[data-property-lease-length-field][hidden]", visible: false)

    select "Freehold", from: "property_tenure"

    expect(page).to have_selector("[data-property-pets-allowed-field]", visible: :hidden)
    expect(page.evaluate_script("document.getElementById('property_pets_allowed').disabled")).to be(true)
    expect(page).to have_selector("[data-property-lease-length-field]", visible: :hidden)
    expect(page.evaluate_script("document.getElementById('property_lease_length_years').disabled")).to be(true)

    select "Leasehold", from: "property_tenure"

    expect(page).to have_selector("[data-property-pets-allowed-field]", visible: :visible)
    expect(page.evaluate_script("document.getElementById('property_pets_allowed').disabled")).to be(false)
    expect(page).to have_selector("[data-property-lease-length-field]", visible: :visible)
    expect(page.evaluate_script("document.getElementById('property_lease_length_years').disabled")).to be(false)

    select "For Sale", from: "property_sale_status"

    expect(page).to have_css("[data-property-furnishing-field][hidden]", visible: false)
    expect(page.evaluate_script("document.getElementById('property_furnishing').disabled")).to be(true)
    expect(page).to have_css("[data-property-rental-only-field][hidden]", visible: false, count: 1)
    expect(page).to have_selector("[data-property-pets-allowed-field]", visible: :hidden)
    expect(page.evaluate_script("document.getElementById('property_deposit_amount').disabled")).to be(true)
    expect(page.evaluate_script("document.getElementById('property_pets_allowed').disabled")).to be(true)

    select "Freehold", from: "property_tenure"

    expect(page).to have_css("[data-property-lease-length-field][hidden]", visible: false)
    expect(page.evaluate_script("document.getElementById('property_lease_length_years').disabled")).to be(true)

    select "Leasehold", from: "property_tenure"

    expect(page).to have_no_css("[data-property-lease-length-field][hidden]", visible: false)
    expect(page.evaluate_script("document.getElementById('property_lease_length_years').disabled")).to be(false)
  end

  it "updates price filter labels when the shared search switches to rentals" do
    visit searches_path
    dismiss_cookie_banner
    expect(page).to have_css("[data-property-search-filters-ready='true']")

    expect(page).to have_css("label[for='min_price']", text: "Min price")
    expect(page).to have_css("label[for='max_price']", text: "Max price")
    expect(page).to have_css("input[data-property-search-min-price-input][placeholder='250,000']")
    expect(page).to have_css("input[data-property-search-max-price-input][placeholder='1,000,000']")

    rental_state = update_shared_search_filter_state("For Rent")

    expect(rental_state).to include(
      "selectedValue" => "For Rent",
      "minLabel" => "Min monthly rental",
      "maxLabel" => "Max monthly rental",
      "minPlaceholder" => "1,500",
      "maxPlaceholder" => "10,000"
    )

    sale_state = update_shared_search_filter_state("For Sale")

    expect(sale_state).to include(
      "selectedValue" => "For Sale",
      "minLabel" => "Min price",
      "maxLabel" => "Max price",
      "minPlaceholder" => "250,000",
      "maxPlaceholder" => "1,000,000"
    )
  end

  it "shows sign-in options for guests on the saved-search panel instead of an email field" do
    visit properties_path
    dismiss_cookie_banner
    wait_for_theme_runtime

    within('[data-testid="saved-search-panel"]') do
      expect(page).to have_link(I18n.t("ui.properties.catalogue.saved_search.sign_in_cta"))
      expect(page).to have_link(I18n.t("ui.properties.catalogue.saved_search.register_cta"))
    end

    expect(page).to have_no_css("#saved_search_email")
  end

  it "localizes native browser validation messages on the registration form" do
    visit new_language_path(language: "de", return_to: new_user_registration_path)

    dismiss_cookie_banner
    wait_for_theme_runtime
    expect(page).to have_field("user_first_name", wait: 5)

    state = page.evaluate_script(<<~JS)
      (() => {
        const input = document.getElementById("user_first_name");
        if (!input) return null;

        input.value = "";
        input.checkValidity();
        const invalid = input.validationMessage;

        input.value = "Anna";
        input.dispatchEvent(new window.Event("input", { bubbles: true }));
        const cleared = input.validationMessage;

        return { invalid, cleared };
      })()
    JS

    expect(state).to include(
      "invalid" => I18n.t("ui.validation.required", locale: :de),
      "cleared" => ""
    )
  end

  it "persists the theme preference across public and admin pages" do
    admin = FactoryBot.create(:admin, email: "theme-admin@example.com", password: "changeme", password_confirmation: "changeme")

    visit root_path
    dismiss_cookie_banner
    wait_for_theme_runtime

    expect_theme_preference("System")

    choose_theme_preference("Dark")

    expect_theme_preference("Dark")
    expect(page.evaluate_script("document.documentElement.dataset.themePreference")).to eq("dark")
    expect(page.evaluate_script("document.documentElement.dataset.theme")).to eq("dark")
    expect(page.evaluate_script("window.localStorage.getItem('gotthekeys-theme-preference')")).to eq("dark")

    visit properties_path
    dismiss_cookie_banner
    wait_for_theme_runtime

    expect_theme_preference("Dark")
    expect(page.evaluate_script("document.documentElement.dataset.theme")).to eq("dark")

    sign_in_as_admin(admin)
    dismiss_cookie_banner
    wait_for_theme_runtime

    expect_theme_preference("Dark")

    choose_theme_preference("System")

    expect_theme_preference("System")
    expect(page.evaluate_script("document.documentElement.dataset.themePreference")).to eq("system")
    expect(page.evaluate_script("window.localStorage.getItem('gotthekeys-theme-preference')")).to eq("system")
  end

  it "uses dark theme surfaces across admin runtime pages" do
    admin = FactoryBot.create(:admin, email: "checkbox-admin@example.com", password: "changeme", password_confirmation: "changeme")

    enable_theme_preference("dark")
    sign_in_as_admin(admin)
    boot_runtime(admin_enquiries_path)

    enquiry_styles = styles_for(<<~JS)
      (() => {
        const checkbox = document.querySelector('[data-testid="lead-filter-spam"]');
        const label = document.querySelector('label[for="spam_only"]');

        return {
          theme: document.documentElement.dataset.theme,
          checkboxBackground: getComputedStyle(checkbox).backgroundColor,
          checkboxBorder: getComputedStyle(checkbox).borderTopColor,
          checkboxRadius: getComputedStyle(checkbox).borderTopLeftRadius,
          labelColor: getComputedStyle(label).color
        };
      })();
    JS

    expect(enquiry_styles).to include(
      "theme" => "dark",
      "checkboxBackground" => "rgba(20, 32, 54, 0.96)",
      "checkboxBorder" => "rgba(167, 188, 220, 0.28)",
      "checkboxRadius" => "7.2px",
      "labelColor" => "rgb(230, 238, 249)"
    )

    boot_runtime(admin_sellers_path)

    user_search_styles = admin_user_search_styles

    expect(user_search_styles).to include(
      "theme" => "dark",
      "labelColor" => "rgb(244, 248, 255)",
      "inputColor" => "rgb(230, 238, 249)",
      "inputBackground" => "rgb(24, 36, 59)",
      "placeholderColor" => "rgb(147, 168, 200)"
    )
    boot_runtime(admin_qa_path)

    qa_styles = styles_for(<<~JS)
      (() => {
        const codeExample = document.querySelector(".detail-inline-list code");

        return {
          theme: document.documentElement.dataset.theme,
          codeBackground: getComputedStyle(codeExample).backgroundColor,
          codeBorder: getComputedStyle(codeExample).borderTopColor,
          codeColor: getComputedStyle(codeExample).color
        };
      })();
    JS

    expect(qa_styles).to include(
      "theme" => "dark",
      "codeBackground" => "rgba(184, 201, 225, 0.12)",
      "codeBorder" => "rgba(132, 156, 194, 0.18)",
      "codeColor" => "rgb(244, 248, 255)"
    )

    boot_runtime(admin_security_path)

    security_styles = styles_for(<<~JS)
      (() => {
        const panel = document.querySelector('[data-testid="admin-security-status-panel"]');
        const statusBadge = document.querySelector('[data-testid="admin-security-global-mode"] .badge');
        const behavior = document.querySelector('[data-testid="admin-security-sign-in-behavior"]');

        return {
          theme: document.documentElement.dataset.theme,
          panelBackground: getComputedStyle(panel).backgroundColor,
          panelBorder: getComputedStyle(panel).borderTopColor,
          badgeBackground: getComputedStyle(statusBadge).backgroundColor,
          badgeColor: getComputedStyle(statusBadge).color,
          behaviorColor: getComputedStyle(behavior).color
        };
      })();
    JS

    expect(security_styles).to include(
      "theme" => "dark",
      "panelBackground" => "rgba(18, 29, 49, 0.86)",
      "panelBorder" => "rgba(116, 145, 188, 0.2)",
      "badgeBackground" => "rgba(240, 187, 90, 0.18)",
      "badgeColor" => "rgb(240, 187, 90)",
      "behaviorColor" => "rgb(230, 238, 249)"
    )
  end

  it "keeps admin user search placeholders lighter in light mode" do
    admin = FactoryBot.create(:admin, email: "users-search-admin-light@example.com", password: "changeme", password_confirmation: "changeme")

    enable_theme_preference("light")
    sign_in_as_admin(admin)
    boot_runtime(admin_sellers_path)

    styles = admin_user_search_styles

    expect(styles).to include(
      "theme" => "light",
      "inputColor" => "rgb(29, 36, 51)",
      "inputBackground" => "rgb(255, 255, 255)",
      "placeholderColor" => "rgb(106, 116, 135)"
    )
  end

  it "uses dark theme surfaces across public runtime pages" do
    enable_theme_preference("dark")
    boot_runtime(legal_index_path(anchor: "legal-purpose"))

    legal_styles = styles_for(<<~JS)
      (() => {
        const nav = document.querySelector(".legal-tabs");
        const card = document.getElementById("legal-purpose");
        const checklistHeading = document.querySelector(".legal-checklist strong");

        return {
          theme: document.documentElement.dataset.theme,
          navBackground: getComputedStyle(nav).backgroundColor,
          navBorder: getComputedStyle(nav).borderTopColor,
          cardBorder: getComputedStyle(card).borderTopColor,
          checklistHeadingColor: getComputedStyle(checklistHeading).color
        };
      })();
    JS

    expect(legal_styles).to include(
      "theme" => "dark",
      "navBackground" => "rgba(20, 32, 54, 0.96)",
      "navBorder" => "rgba(132, 156, 194, 0.18)",
      "cardBorder" => "rgba(116, 145, 188, 0.2)",
      "checklistHeadingColor" => "rgb(244, 248, 255)"
    )

    boot_runtime(cookie_policy_index_path)
    expect(page).to have_css("#cookie-preferences")
    expect(page).to have_css(".cookie-policy-card--summary")

    cookie_styles = styles_for(<<~JS)
      (() => {
        const settingsCard = document.getElementById("cookie-preferences");
        const summaryCard = document.querySelector(".cookie-policy-card--summary");
        const settingsHeading = settingsCard.querySelector("h2");
        const summaryHeading = summaryCard.querySelector("h2");

        return {
          theme: document.documentElement.dataset.theme,
          settingsBackground: getComputedStyle(settingsCard).backgroundColor,
          summaryBackground: getComputedStyle(summaryCard).backgroundColor,
          settingsHeadingColor: getComputedStyle(settingsHeading).color,
          summaryHeadingColor: getComputedStyle(summaryHeading).color
        };
      })();
    JS

    expect(cookie_styles).to include(
      "theme" => "dark",
      "settingsBackground" => "rgba(20, 32, 54, 0.96)",
      "summaryBackground" => "rgba(20, 32, 54, 0.96)",
      "settingsHeadingColor" => "rgb(244, 248, 255)",
      "summaryHeadingColor" => "rgb(244, 248, 255)"
    )

    boot_runtime(how_it_works_path)
    expect(page).to have_css(".page-hero.how-hero")
    expect(page).to have_css(".how-hero__panel")

    how_hero_styles = styles_for(<<~JS)
      (() => {
        const hero = document.querySelector(".page-hero.how-hero");
        const copy = document.querySelector(".how-hero__copy");
        const panel = document.querySelector(".how-hero__panel");
        const panelHeading = panel.querySelector("h2");
        const panelBody = panel.querySelector("p");

        return {
          theme: document.documentElement.dataset.theme,
          heroBackground: getComputedStyle(hero).backgroundColor,
          copyColor: getComputedStyle(copy).color,
          panelBackground: getComputedStyle(panel).backgroundColor,
          panelHeadingColor: getComputedStyle(panelHeading).color,
          panelBodyColor: getComputedStyle(panelBody).color
        };
      })();
    JS

    expect(how_hero_styles).to include(
      "theme" => "dark",
      "heroBackground" => "rgba(18, 29, 49, 0.86)",
      "copyColor" => "rgb(230, 238, 249)",
      "panelBackground" => "rgba(18, 29, 49, 0.86)",
      "panelHeadingColor" => "rgb(244, 248, 255)",
      "panelBodyColor" => "rgb(230, 238, 249)"
    )

    how_nav_styles = styles_for(<<~JS)
      (() => {
        const jumpNav = document.querySelector(".how-jump-nav");
        const jumpTab = document.querySelector(".how-jump-tab");
        const jumpIndex = document.querySelector(".how-jump-tab__index");
        const jumpLabel = document.querySelector(".how-jump-tab__label");
        const timelineBadge = document.querySelector(".how-timeline-card__badge");
        const stageCard = document.querySelector(".how-stage-card");
        const stageStep = document.querySelector(".how-stage-card__step");
        const marketingFeature = document.querySelector(".how-marketing-card");
        const callout = document.querySelector(".how-callout");
        const finishCard = document.querySelector(".how-finish-card");

        return {
          theme: document.documentElement.dataset.theme,
          jumpNavBackground: getComputedStyle(jumpNav).backgroundColor,
          jumpTabBackground: getComputedStyle(jumpTab).backgroundColor,
          jumpIndexBackground: getComputedStyle(jumpIndex).backgroundColor,
          jumpIndexColor: getComputedStyle(jumpIndex).color,
          jumpLabelColor: getComputedStyle(jumpLabel).color,
          timelineBadgeColor: getComputedStyle(timelineBadge).color,
          stageBackground: getComputedStyle(stageCard).backgroundColor,
          stageStepBackground: getComputedStyle(stageStep).backgroundColor,
          stageStepColor: getComputedStyle(stageStep).color,
          marketingFeatureBackground: getComputedStyle(marketingFeature).backgroundColor,
          calloutBackground: getComputedStyle(callout).backgroundColor,
          finishBackground: getComputedStyle(finishCard).backgroundColor
        };
      })();
    JS

    expect(how_nav_styles).to include(
      "theme" => "dark",
      "jumpNavBackground" => "rgba(20, 32, 54, 0.96)",
      "jumpTabBackground" => "rgba(20, 32, 54, 0.96)",
      "jumpIndexBackground" => "rgba(20, 32, 54, 0.96)",
      "jumpIndexColor" => "rgb(168, 199, 255)",
      "jumpLabelColor" => "rgb(244, 248, 255)",
      "timelineBadgeColor" => "rgb(168, 199, 255)",
      "stageBackground" => "rgba(18, 29, 49, 0.86)",
      "stageStepBackground" => "rgba(20, 32, 54, 0.96)",
      "stageStepColor" => "rgb(168, 199, 255)",
      "marketingFeatureBackground" => "rgba(18, 29, 49, 0.86)",
      "calloutBackground" => "rgba(18, 29, 49, 0.86)",
      "finishBackground" => "rgba(18, 29, 49, 0.86)"
    )

    boot_runtime(contact_us_path)

    contact_styles = styles_for(<<~JS)
      (() => {
        const jumpNav = document.querySelector(".contact-jump-nav");
        const jumpTab = document.querySelector(".contact-jump-tab");
        const jumpLabel = document.querySelector(".contact-jump-tab__label");
        const heroHint = document.querySelector(".contact-hero__hint");
        const formCard = document.querySelector(".contact-form-card");
        const formSurface = document.querySelector(".contact-form");
        const directoryPersonName = document.querySelector(".contact-person-card strong");
        const directoryPersonEmail = document.querySelector(".contact-person-card__body span");
        const mapStrong = document.querySelector(".contact-map-card__details strong");
        const mapBadge = document.querySelector("#contact-location .badge");
        const noteCard = document.querySelector(".contact-note-card");
        const noteBadge = document.querySelector(".contact-note-card .section-heading__eyebrow");

        return {
          theme: document.documentElement.dataset.theme,
          jumpNavBackground: getComputedStyle(jumpNav).backgroundColor,
          jumpTabBackground: getComputedStyle(jumpTab).backgroundColor,
          jumpLabelColor: getComputedStyle(jumpLabel).color,
          heroHintColor: getComputedStyle(heroHint).color,
          formCardBackground: getComputedStyle(formCard).backgroundColor,
          formSurfaceBackground: getComputedStyle(formSurface).backgroundColor,
          directoryPersonNameColor: getComputedStyle(directoryPersonName).color,
          directoryPersonEmailColor: getComputedStyle(directoryPersonEmail).color,
          mapStrongColor: getComputedStyle(mapStrong).color,
          hasMapBadge: Boolean(mapBadge),
          noteBadgeBackground: getComputedStyle(noteBadge).backgroundColor,
          noteBadgeColor: getComputedStyle(noteBadge).color,
          noteCardBackground: getComputedStyle(noteCard).backgroundColor
        };
      })();
    JS

    expect(contact_styles).to include(
      "theme" => "dark",
      "jumpNavBackground" => "rgba(20, 32, 54, 0.96)",
      "jumpTabBackground" => "rgba(20, 32, 54, 0.96)",
      "jumpLabelColor" => "rgb(230, 238, 249)",
      "heroHintColor" => "rgb(230, 238, 249)",
      "formCardBackground" => "rgba(18, 29, 49, 0.86)",
      "formSurfaceBackground" => "rgba(20, 32, 54, 0.96)",
      "directoryPersonNameColor" => "rgb(244, 248, 255)",
      "directoryPersonEmailColor" => "rgb(230, 238, 249)",
      "mapStrongColor" => "rgb(244, 248, 255)",
      "hasMapBadge" => false,
      "noteBadgeBackground" => "rgba(184, 201, 225, 0.12)",
      "noteBadgeColor" => "rgb(244, 248, 255)",
      "noteCardBackground" => "rgba(18, 29, 49, 0.86)"
    )
  end

  it "keeps signed-in dark mode form surfaces readable" do
    user = FactoryBot.create(:user, email: "dark-form-controls@example.com", password: "changeme", password_confirmation: "changeme")

    enable_theme_preference("dark")
    sign_in_as_user(user)
    boot_runtime(new_property_path)

    form_styles = styles_for(<<~JS)
      (() => {
        const textField = document.getElementById("property_address_line_1");
        const selectField = document.getElementById("property_listing_state");
        const textareaField = document.getElementById("property_property_description");
        const dateField = document.getElementById("property_available_from");

        return {
          theme: document.documentElement.dataset.theme,
          textColor: getComputedStyle(textField).color,
          textCaret: getComputedStyle(textField).caretColor,
          textFill: getComputedStyle(textField).webkitTextFillColor,
          selectColor: getComputedStyle(selectField).color,
          selectFill: getComputedStyle(selectField).webkitTextFillColor,
          textareaColor: getComputedStyle(textareaField).color,
          textareaCaret: getComputedStyle(textareaField).caretColor,
          dateColor: getComputedStyle(dateField).color,
          dateCaret: getComputedStyle(dateField).caretColor,
          dateFill: getComputedStyle(dateField).webkitTextFillColor
        };
      })();
    JS

    expect(form_styles).to include(
      "theme" => "dark",
      "textColor" => "rgb(230, 238, 249)",
      "textCaret" => "rgb(230, 238, 249)",
      "textFill" => "rgb(230, 238, 249)",
      "selectColor" => "rgb(230, 238, 249)",
      "selectFill" => "rgb(230, 238, 249)",
      "textareaColor" => "rgb(230, 238, 249)",
      "textareaCaret" => "rgb(230, 238, 249)",
      "dateColor" => "rgb(230, 238, 249)",
      "dateCaret" => "rgb(230, 238, 249)",
      "dateFill" => "rgb(230, 238, 249)"
    )

    boot_runtime(properties_path)

    saved_search_styles = styles_for(<<~JS)
      (() => {
        const alertsLabel = document.querySelector('label[for="saved_search_alerts_enabled"]');
        const alertsInput = document.getElementById("saved_search_alerts_enabled");

        alertsInput.focus();

        return {
          theme: document.documentElement.dataset.theme,
          alertsLabelColor: getComputedStyle(alertsLabel).color
        };
      })();
    JS

    expect(saved_search_styles).to include(
      "theme" => "dark",
      "alertsLabelColor" => "rgb(230, 238, 249)"
    )
  end

  it "uses the default foundation pagination treatment in light mode" do
    user = FactoryBot.create(:user, email: "pagination-light-mode@example.com")

    13.times do |index|
      FactoryBot.create(
        :property,
        user:,
        address_line_1: "Pagination Light Mode #{index + 1}",
        postcode: format("LM1 %<n>AA", n: index + 1)
      )
    end

    enable_theme_preference("light")
    boot_runtime(properties_path)

    styles = page.evaluate_script(<<~JS)
      (() => {
        const link = document.querySelector(".pagination li:not(.current):not(.disabled):not(.ellipsis) a");
        const current = document.querySelector(".pagination .current a");
        const disabled = document.querySelector(".pagination .disabled span");

        return {
          theme: document.documentElement.dataset.theme,
          linkColor: getComputedStyle(link).color,
          linkBackground: getComputedStyle(link).backgroundColor,
          currentColor: getComputedStyle(current).color,
          currentLinkBackground: getComputedStyle(current).backgroundColor,
          currentContainerBackground: getComputedStyle(current.parentElement).backgroundColor,
          currentContainerPadding: getComputedStyle(current.parentElement).paddingTop,
          currentRadius: getComputedStyle(current.parentElement).borderTopLeftRadius,
          currentWidth: Math.round(current.parentElement.getBoundingClientRect().width),
          currentHeight: Math.round(current.parentElement.getBoundingClientRect().height),
          disabledColor: getComputedStyle(disabled).color
        };
      })();
    JS

    expect(styles).to include(
      "theme" => "light",
      "linkColor" => "rgb(10, 10, 10)",
      "linkBackground" => "rgba(0, 0, 0, 0)",
      "currentColor" => "rgb(254, 254, 254)",
      "currentLinkBackground" => "rgba(0, 0, 0, 0)",
      "currentContainerBackground" => "rgb(23, 121, 186)",
      "currentContainerPadding" => "0px",
      "currentRadius" => "999px",
      "disabledColor" => "rgb(202, 202, 202)"
    )

    expect(styles["currentWidth"]).to eq(styles["currentHeight"])
  end

  it "sweeps back to the property results when catalogue pagination is used" do
    user = FactoryBot.create(:user, email: "pagination-scroll-user@example.com")

    13.times do |index|
      FactoryBot.create(
        :property,
        user:,
        address_line_1: "Pagination Scroll #{index + 1}",
        postcode: format("PS1 %<n>AA", n: index + 1)
      )
    end

    visit properties_path
    dismiss_cookie_banner
    wait_for_theme_runtime

    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    page_two_href = page.evaluate_script(<<~JS)
      (() => {
        const links = Array.from(document.querySelectorAll("[data-pagination-scroll-nav] .pagination a"));
        return links.filter((link) => link.textContent.trim() === "2").at(-1)?.href;
      })();
    JS
    page.execute_script(<<~JS, page_two_href)
      const href = arguments[0];
      const url = new URL(href, window.location.origin);
      window.sessionStorage.setItem("gotthekeys-pagination-scroll", `${url.pathname}${url.search}`);
      window.location.assign(href);
    JS

    expect(page).to have_current_path(properties_path(page: 2), ignore_query: false)
    expect(page).to have_css("html[data-pagination-scroll-state='complete']", wait: 5)

    styles = page.evaluate_script(<<~JS)
      (() => {
        const target = document.querySelector("[data-pagination-scroll-target]");
        const current = document.querySelector(".pagination .current");

        return {
          state: document.documentElement.dataset.paginationScrollState,
          currentPage: current?.textContent?.trim(),
          scrollY: window.scrollY,
          targetTop: Math.round(target.getBoundingClientRect().top)
        };
      })();
    JS

    expect(styles["state"]).to eq("complete")
    expect(styles["currentPage"]).to eq("2")
    expect(styles["scrollY"]).to be > 200
    expect(styles["targetTop"]).to be_between(0, 160)
  end

  it "uses readable pagination controls on the catalogue page in dark mode" do
    user = FactoryBot.create(:user, email: "pagination-user@example.com")

    13.times do |index|
      FactoryBot.create(
        :property,
        user:,
        address_line_1: "Pagination Dark Mode #{index + 1}",
        postcode: format("DM1 %<n>AA", n: index + 1)
      )
    end

    enable_theme_preference("dark")
    boot_runtime(properties_path)

    styles = page.evaluate_script(<<~JS)
      (() => {
        const link = document.querySelector(".pagination li:not(.current):not(.disabled):not(.ellipsis) a");
        const current = document.querySelector(".pagination .current a");
        const disabled = document.querySelector(".pagination .disabled span");

        return {
          theme: document.documentElement.dataset.theme,
          linkColor: getComputedStyle(link).color,
          linkBackground: getComputedStyle(link).backgroundColor,
          currentColor: getComputedStyle(current).color,
          currentLinkBackground: getComputedStyle(current).backgroundColor,
          currentContainerBackground: getComputedStyle(current.parentElement).backgroundColor,
          currentContainerPadding: getComputedStyle(current.parentElement).paddingTop,
          currentRadius: getComputedStyle(current.parentElement).borderTopLeftRadius,
          currentWidth: Math.round(current.parentElement.getBoundingClientRect().width),
          currentHeight: Math.round(current.parentElement.getBoundingClientRect().height),
          disabledColor: getComputedStyle(disabled).color
        };
      })();
    JS

    expect(styles).to include(
      "theme" => "dark",
      "linkColor" => "rgb(230, 238, 249)",
      "linkBackground" => "rgba(0, 0, 0, 0)",
      "currentColor" => "rgb(255, 255, 255)",
      "currentLinkBackground" => "rgba(0, 0, 0, 0)",
      "currentContainerBackground" => "rgb(121, 171, 255)",
      "currentContainerPadding" => "0px",
      "currentRadius" => "999px",
      "disabledColor" => "rgb(166, 180, 202)"
    )

    expect(styles["currentWidth"]).to eq(styles["currentHeight"])
  end
end
