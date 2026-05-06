require "rails_helper"
require "nokogiri"

RSpec.describe "SEO meta tags", type: :request do
  around do |example|
    original_public_indexing_enabled = Rails.configuration.x.got_the_keys.public_indexing_enabled
    original_public_indexing_env = ENV["PUBLIC_INDEXING_ENABLED"]

    Rails.configuration.x.got_the_keys.public_indexing_enabled = true
    ENV["PUBLIC_INDEXING_ENABLED"] = "true"

    example.run
  ensure
    Rails.configuration.x.got_the_keys.public_indexing_enabled = original_public_indexing_enabled
    ENV["PUBLIC_INDEXING_ENABLED"] = original_public_indexing_env
  end

  def document
    Nokogiri::HTML.parse(response.body)
  end

  it "keeps public auth entry pages out of the index" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(document.at_css('meta[name="robots"]')["content"]).to eq("noindex, nofollow")
    expect(document.at_css('meta[name="description"]')["content"]).to eq(
      "Sign in to your GotTheKeys account to manage saved homes, viewings, offers, and listing activity."
    )
  end

  it "canonicalises generic searches to the property catalogue" do
    get searches_path(q: "Sevenoaks", page: 3)

    expect(response).to have_http_status(:ok)
    expect(document.at_css('meta[name="robots"]')["content"]).to eq("noindex, follow")
    expect(document.at_css('link[rel="canonical"]')["href"]).to eq(
      properties_url(q: "Sevenoaks")
    )
  end

  it "removes pagination from property catalogue canonicals" do
    FactoryBot.create(:property, town_city: "Westerham")

    get properties_path(town: "Westerham", page: 9)

    expect(response).to have_http_status(:ok)
    expect(document.at_css('meta[name="robots"]')["content"]).to eq("noindex, follow")
    expect(document.at_css('link[rel="canonical"]')["href"]).to eq(
      properties_url(town: "Westerham")
    )
  end
end
