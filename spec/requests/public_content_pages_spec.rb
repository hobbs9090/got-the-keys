require "rails_helper"

RSpec.describe "Public content pages", type: :request do
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

  it "wraps the for sale bottom pagination in the shared results footer spacing" do
    get "/for_sale"

    document = Nokogiri::HTML(response.body)
    footer = document.at_css(".property-results-panel__footer")

    expect(response).to have_http_status(:ok)
    expect(footer).to be_present
  end

  it "wraps the for rent bottom pagination in the shared results footer spacing" do
    get "/for_rent"

    document = Nokogiri::HTML(response.body)
    footer = document.at_css(".property-results-panel__footer")

    expect(response).to have_http_status(:ok)
    expect(footer).to be_present
  end
end
