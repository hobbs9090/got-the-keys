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

  pages = [
    { description: "search", path: "/searches", text: "Search listings and booking availability together" },
    { description: "legal", path: "/legal", text: "A plain-English summary of the key terms and responsibilities that apply when you use the site." },
    { description: "cookie policy", path: "/cookie_policy", text: "This site uses essential cookies to keep sign-in, forms, and language preferences working." },
    { description: "how it works", path: "/how_it_works", text: "How to market your home with more clarity and less fluff" },
    { description: "about us", path: "/about_us", text: "We built the service for owners who want clearer costs, better control, and a more direct route to serious enquiries." },
    { description: "contact us", path: "/contact_us", text: "Get in Touch!" },
    { description: "blog", path: "/blog", text: "Five Small Listing Improvements That Generate Better Enquiries" },
    { description: "coffee", path: "/coffee", text: I18n.t("coffeescript.blurb") },
    { description: "for sale", path: "/for_sale", text: "Homes available to buy" },
    { description: "for rent", path: "/for_rent", text: "Homes available to rent" }
  ]

  pages.each do |page|
    it "renders the #{page[:description]} page" do
      get page[:path]

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(page[:text])
      expect(response.body).not_to include('role="content"')
    end
  end

  it "redirects the legacy baits path to the blog" do
    get "/baits"

    expect(response).to redirect_to("/blog")
  end

  it "renders the refreshed blog editorial layout" do
    get "/blog"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-testid="blog-featured-post"')
    expect(response.body).to include(I18n.t("blog.hero_title"))
    expect(response.body.scan('data-testid="blog-story-card"').count).to eq(3)
    expect(response.body).to include(I18n.t("blog.story_3_title"))
  end

  it "renders the refreshed about us company layout" do
    get "/about_us"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-testid="about-story-card"')
    expect(response.body).to include(I18n.t("about_us.hero_title"))
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
    expect(input_placeholder("min_price")).to eq("250,000")
    expect(input_placeholder("max_price")).to eq("1,000,000")

    get searches_path, params: { sale_status: Property::SALE_STATUSES[:for_rent] }
    expect(label_text("min_price")).to eq(I18n.t("ui.properties.filters.min_monthly_rental"))
    expect(label_text("max_price")).to eq(I18n.t("ui.properties.filters.max_monthly_rental"))
    expect(input_placeholder("min_price")).to eq("1,500")
    expect(input_placeholder("max_price")).to eq("10,000")

    get for_sale_index_path
    expect(label_text("min_price")).to eq(I18n.t("ui.properties.filters.min_price"))
    expect(label_text("max_price")).to eq(I18n.t("ui.properties.filters.max_price"))
    expect(input_placeholder("min_price")).to eq("250,000")
    expect(input_placeholder("max_price")).to eq("1,000,000")

    get for_rent_index_path
    expect(label_text("min_price")).to eq(I18n.t("ui.properties.filters.min_monthly_rental"))
    expect(label_text("max_price")).to eq(I18n.t("ui.properties.filters.max_monthly_rental"))
    expect(input_placeholder("min_price")).to eq("1,500")
    expect(input_placeholder("max_price")).to eq("10,000")
  end
end
