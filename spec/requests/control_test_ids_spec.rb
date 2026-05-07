require "rails_helper"
require "nokogiri"

RSpec.describe "Control test IDs", type: :request do
  def document
    Nokogiri::HTML.parse(response.body)
  end

  def expect_user_controls_to_have_test_ids
    controls = document.css('form, button, select, textarea, a.button, input:not([type="hidden"])')
    missing = controls.reject { |node| node["data-testid"].present? }

    expect(missing.map { |node| "#{node.name}##{node["id"]}.#{node["class"]}" }).to be_empty
  end

  it "adds stable selectors to public page buttons and raw contact controls" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect_user_controls_to_have_test_ids
    expect(document.at_css('[data-testid="hero-carousel-next"]')).to be_present

    get contact_us_path

    expect(response).to have_http_status(:ok)
    expect_user_controls_to_have_test_ids
    expect(document.at_css('[data-testid="contact-form"]')).to be_present
  end

  it "adds selectors to generated auth and cookie controls without replacing explicit selectors" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect_user_controls_to_have_test_ids
    expect(document.at_css('[data-testid="sign-in-email"]')).to be_present

    get cookie_policy_index_path

    expect(response).to have_http_status(:ok)
    expect_user_controls_to_have_test_ids
  end

  it "adds selectors to catalogue filter controls and links styled as buttons" do
    FactoryBot.create(:property, address_line_1: "Selector House", town_city: "Sevenoaks")

    get properties_path

    expect(response).to have_http_status(:ok)
    expect_user_controls_to_have_test_ids
    expect(document.at_css('[data-testid="property-filter-form"]')).to be_present
  end
end
