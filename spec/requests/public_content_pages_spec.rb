require "rails_helper"

RSpec.describe "Public content pages", type: :request do
  def parsed_html
    Nokogiri::HTML(response.body)
  end

  def label_text(for_id)
    parsed_html.at_css(%(label[for="#{for_id}"]))&.text&.strip
  end

  def input_placeholder(field_id)
    parsed_html.at_css(%(input##{field_id}))&.[]("placeholder")
  end

  def input_attribute(field_id, attribute)
    parsed_html.at_css(%(input##{field_id}))&.[](attribute)
  end

  def hint_attribute(field_id, attribute)
    parsed_html.at_css(%(##{field_id}_listing_type_hint))&.[](attribute)
  end

  pages = [
    { description: "search", path: "/searches", text: "Search sale and rental listings together" },
    { description: "legal", path: "/legal", text: "A plain-English summary of the key terms and responsibilities that apply when you use the site." },
    { description: "cookie policy", path: "/cookie_policy", text: "This site uses essential cookies to keep sign-in, forms, and language preferences working." },
    { description: "how it works", path: "/how_it_works", text: "How to market your home with more clarity and less fluff" },
    { description: "about us", path: "/about_us", text: "We built the service for owners who want clearer costs, better control, and a more direct route to serious enquiries." },
    { description: "contact us", path: "/contact_us", text: "Get in touch" },
    { description: "blog", path: "/blog", text: "Five Small Listing Improvements That Generate Better Enquiries" },
    { description: "for sale", path: "/for_sale", text: "Homes available to buy" },
    { description: "for rent", path: "/for_rent", text: "Homes available to rent" }
  ]

  pages.each do |page|
    it "renders the #{page[:description]} page" do
      get page[:path]
      document = parsed_html

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(page[:text])
      expect(response.body).not_to include('role="content"')
      expect(document.at_css("h1")).to be_present
      expect(document.at_css('meta[name="description"]')&.[]("content")).to be_present
      expect(document.at_css('meta[name="description"]')["content"]).not_to be_blank
      expect(document.at_css('meta[name="robots"]')["content"]).to eq("noindex, nofollow")
      expect(document.at_css('link[rel="canonical"]')&.[]("href")).to be_present
    end
  end

  it "redirects the legacy baits path to the blog" do
    get "/baits"

    expect(response).to redirect_to("/blog")
  end

  it "renders the refreshed blog editorial layout" do
    get "/blog"
    document = parsed_html

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-testid="blog-featured-post"')
    expect(response.body).to include(I18n.t("blog.hero_title"))
    expect(response.body.scan('data-testid="blog-story-card"').count).to eq(3)
    expect(response.body).to include(I18n.t("blog.story_3_title"))
    expect(document.css('a[href^="/blog/"]').map { |link| link["href"] }.uniq.count).to eq(4)
  end

  it "renders the blog post pages with full article content" do
    slugs = [
      "five-small-listing-improvements-that-generate-better-enquiries",
      "why-quick-follow-up-still-decides-whether-serious-buyers-stay-engaged",
      "brochure-floor-plan-or-both",
      "first-three-viewing-questions"
    ]

    slugs.each do |slug|
      get blog_path(slug)

      expect(response).to have_http_status(:ok)
      expect(parsed_html.at_css('[data-testid="blog-post"]')).to be_present
      expect(parsed_html.css(".blog-post__content p").count).to be >= 6
      expect(parsed_html.at_css('meta[name="description"]')["content"]).to be_present
      expect(response.body).to include(I18n.t("blog.back_to_blog"))
    end
  end

  it "renders the refreshed about us company layout" do
    get "/about_us"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-testid="about-story-card"')
    expect(response.body).to include(I18n.t("about_us.hero_title"))
  end

  it "exposes a stable terms anchor on the legal page" do
    get "/legal"

    expect(response).to have_http_status(:ok)
    expect(parsed_html.at_css("#terms-of-service")).to be_present
    expect(response.body).to include("GotTheKeys is a QA testing harness masquerading as a property site.")
  end

  it "renders a non-placeholder contact location that matches the map postcode" do
    get "/contact_us"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sevenoaks and Westerham")
    expect(response.body).to include("Kent, TN16 1ET")
    expect(response.body).to include("TN16+1ET")
    expect(parsed_html.at_css(".contact-map-card__frame--static")).to be_present
    expect(parsed_html.at_css(".contact-map-card .contact-map-card__frame iframe")).not_to be_present
    expect(response.body).not_to include("123 Awesome Road")
    expect(response.body).not_to include("TN16 4AB")
  end

  it "pre-fills the contact form with the signed-in user's name and email" do
    user = FactoryBot.create(:user, first_name: "Tomas", last_name: "Reed", email: "tomas.reed@example.com")
    sign_in(user)

    get "/contact_us"

    document = parsed_html
    expect(document.at_css(%([data-testid="contact-your-name"]))["value"]).to eq("Tomas Reed")
    expect(document.at_css(%([data-testid="contact-your-email"]))["value"]).to eq("tomas.reed@example.com")
  end

  it "leaves the contact form blank for guests" do
    get "/contact_us"

    document = parsed_html
    expect(document.at_css(%([data-testid="contact-your-name"]))["value"].to_s).to be_empty
    expect(document.at_css(%([data-testid="contact-your-email"]))["value"].to_s).to be_empty
  end

  it "keeps the how it works publishing checklist in the main content column" do
    get "/how_it_works"

    document = parsed_html

    expect(response).to have_http_status(:ok)
    expect(document.at_css(".how-marketing-main > .how-checklist-card")).to be_present
    expect(document.at_css(".how-marketing-sidebar .how-checklist-card")).not_to be_present
  end

  it "uses the shared top and bottom pagination layout on the public listing pages" do
    user = FactoryBot.create(:user)

    14.times do |index|
      FactoryBot.create(
        :property,
        user:,
        sale_status: Property::SALE_STATUSES[:for_sale],
        address_line_1: "Sale Listing #{index + 1}",
        postcode: format("SE1 %<n>AA", n: index + 1)
      )
      FactoryBot.create(
        :property,
        :for_rent,
        user:,
        address_line_1: "Rent Listing #{index + 1}",
        postcode: format("SW1 %<n>BB", n: index + 1)
      )
    end

    ["/searches", "/for_sale", "/for_rent"].each do |path|
      get path

      document = Nokogiri::HTML(response.body)

      expect(response).to have_http_status(:ok)
      expect(document.css(".property-results-stack > .property-results-pagination").count).to eq(2)
      expect(document.at_css(".site-card.property-results-panel .pagination")).not_to be_present
    end
  end

  it "uses monthly rental labels on rent-only search forms and generic price labels elsewhere" do
    get searches_path
    expect(label_text("min_price")).to eq(I18n.t("ui.properties.filters.min_price"))
    expect(label_text("max_price")).to eq(I18n.t("ui.properties.filters.max_price"))
    expect(input_placeholder("min_price")).to be_nil
    expect(input_placeholder("max_price")).to be_nil
    expect(input_attribute("min_price", "disabled")).to eq("disabled")
    expect(input_attribute("max_price", "disabled")).to eq("disabled")
    expect(input_attribute("min_price", "aria-describedby")).to eq("min_price_listing_type_hint")
    expect(input_attribute("max_price", "aria-describedby")).to eq("max_price_listing_type_hint")
    expect(parsed_html.at_css("#min_price_listing_type_hint").text.squish).to eq(I18n.t("ui.properties.filters.price_requires_listing_type"))
    expect(parsed_html.at_css("#max_price_listing_type_hint").text.squish).to eq(I18n.t("ui.properties.filters.price_requires_listing_type"))

    get searches_path, params: { sale_status: Property::SALE_STATUSES[:for_rent] }
    expect(label_text("min_price")).to eq(I18n.t("ui.properties.filters.min_monthly_rental"))
    expect(label_text("max_price")).to eq(I18n.t("ui.properties.filters.max_monthly_rental"))
    expect(input_placeholder("min_price")).to be_nil
    expect(input_placeholder("max_price")).to be_nil
    expect(input_attribute("min_price", "disabled")).to be_nil
    expect(input_attribute("max_price", "disabled")).to be_nil
    expect(hint_attribute("min_price", "hidden")).not_to be_nil
    expect(hint_attribute("max_price", "hidden")).not_to be_nil

    get for_sale_index_path
    expect(label_text("min_price")).to eq(I18n.t("ui.properties.filters.min_price"))
    expect(label_text("max_price")).to eq(I18n.t("ui.properties.filters.max_price"))
    expect(input_placeholder("min_price")).to be_nil
    expect(input_placeholder("max_price")).to be_nil
    expect(input_attribute("min_price", "disabled")).to be_nil
    expect(input_attribute("max_price", "disabled")).to be_nil
    expect(parsed_html.at_css("#min_price_listing_type_hint")).to be_nil
    expect(parsed_html.at_css("#max_price_listing_type_hint")).to be_nil

    get for_rent_index_path
    expect(label_text("min_price")).to eq(I18n.t("ui.properties.filters.min_monthly_rental"))
    expect(label_text("max_price")).to eq(I18n.t("ui.properties.filters.max_monthly_rental"))
    expect(input_placeholder("min_price")).to be_nil
    expect(input_placeholder("max_price")).to be_nil
    expect(input_attribute("min_price", "disabled")).to be_nil
    expect(input_attribute("max_price", "disabled")).to be_nil
    expect(parsed_html.at_css("#min_price_listing_type_hint")).to be_nil
    expect(parsed_html.at_css("#max_price_listing_type_hint")).to be_nil
  end

  it "does not render placeholder examples or visible question-mark hints on public price filters" do
    [
      searches_path,
      properties_path,
      for_sale_index_path,
      for_rent_index_path
    ].each do |path|
      get path

      document = parsed_html
      min_price = document.at_css("input#min_price")
      max_price = document.at_css("input#max_price")

      expect(response).to have_http_status(:ok)
      expect(min_price).to be_present
      expect(max_price).to be_present
      expect(min_price["placeholder"]).to be_nil
      expect(max_price["placeholder"]).to be_nil
      expect(document.css(".property-filters__hint-trigger")).to be_empty
      expect(document.css(".property-filters__label-row").map(&:text).join(" ")).not_to include("?")
    end
  end

  it "adds search form validation attributes for query and price inputs" do
    get searches_path

    expect(input_attribute("q", "maxlength")).to eq("100")
    expect(input_attribute("min_price", "pattern")).to eq("[0-9,\\s]*")
    expect(input_attribute("max_price", "pattern")).to eq("[0-9,\\s]*")
    expect(input_attribute("min_price", "maxlength")).to eq("15")
    expect(input_attribute("max_price", "maxlength")).to eq("15")

    get properties_path

    expect(parsed_html.at_css("input#saved_search_email")).to be_nil
    expect(parsed_html.at_css('[data-testid="saved-search-panel"] a[href*="sign_in"]')).to be_present
    expect(input_attribute("min_price", "disabled")).to eq("disabled")
    expect(input_attribute("max_price", "disabled")).to eq("disabled")
  end

  it "includes a hidden price-range validation hint on catalogue filter forms" do
    get for_sale_index_path

    hint = parsed_html.at_css(%([data-testid="price-range-hint"]))
    expect(hint).to be_present
    expect(hint["hidden"]).not_to be_nil
    expect(hint.text.strip).to eq(I18n.t("ui.properties.filters.price_range_inverted"))
  end
end
