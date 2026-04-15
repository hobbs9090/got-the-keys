require "rails_helper"

RSpec.describe "Public localization and footer fit", type: :system, js: true do
  let(:pages) do
    [
      { path: -> { legal_index_path }, key: "legal.blurb" },
      { path: -> { cookie_policy_index_path }, key: "cookie_policy.hero_body" },
      { path: -> { how_it_works_path }, key: "how_it_works.hero_title" },
      { path: -> { about_us_path }, key: "about_us.hero_title" },
      { path: -> { contact_us_path }, key: "contact_us.get_in_touch" },
      { path: -> { blog_index_path }, key: "blog.hero_title" }
    ]
  end

  let(:locales) { %w[de fr it zh] }
  let(:representative_locale) { "de" }
  let(:translation_smoke_pages) do
    [
      { path: -> { legal_index_path }, key: "legal.blurb" },
      { path: -> { contact_us_path }, key: "contact_us.get_in_touch" }
    ]
  end

  it "renders translated public pages across the supported locales on representative routes" do
    page.current_window.resize_to(1280, 900)

    locales.each do |locale|
      translation_smoke_pages.each do |page_config|
        visit new_language_path(language: locale, return_to: instance_exec(&page_config[:path]))

        expect(page).to have_css(%(html[lang="#{locale}"]), visible: false)
        expect(page).to have_text(I18n.t(page_config[:key], locale: locale.to_sym))
      end
    end
  end

  it "renders the broader public page set in a representative translated locale" do
    page.current_window.resize_to(1280, 900)

    pages.each do |page_config|
      visit new_language_path(language: representative_locale, return_to: instance_exec(&page_config[:path]))

      expect(page).to have_css(%(html[lang="#{representative_locale}"]), visible: false)
      expect(page).to have_text(I18n.t(page_config[:key], locale: representative_locale.to_sym))
    end
  end

  it "keeps the translated footer inside the viewport" do
    page.current_window.resize_to(1280, 900)

    %w[de zh].each do |locale|
      visit new_language_path(language: locale, return_to: properties_path)

      fit = page.evaluate_script(<<~JS)
        (() => {
          const footer = document.querySelector(".site-footer__inner");
          const links = document.querySelector(".site-footer__links");
          const utility = document.querySelector(".site-footer__utility");
          const footerRect = footer ? footer.getBoundingClientRect() : null;
          const fitsWithinFooter = (element) => {
            if (!element || !footerRect) return false;

            const rect = element.getBoundingClientRect();
            return rect.left >= footerRect.left - 1 && rect.right <= footerRect.right + 1;
          };

          return {
            documentFits: document.documentElement.scrollWidth <= document.documentElement.clientWidth + 1,
            footerFits: footer ? footer.scrollWidth <= footer.clientWidth + 1 : false,
            linksFit: fitsWithinFooter(links),
            utilityFit: fitsWithinFooter(utility)
          };
        })();
      JS

      expect(fit).to include(
        "documentFits" => true,
        "footerFits" => true,
        "linksFit" => true,
        "utilityFit" => true
      )
    end
  end
end
