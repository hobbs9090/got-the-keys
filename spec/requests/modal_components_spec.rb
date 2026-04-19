require "rails_helper"
require "nokogiri"

RSpec.describe "Modal components" do
  it "uses the shared modal contract on the contact page" do
    get contact_us_path

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    trigger = document.at_css('[data-modal-trigger="map-modal"]')
    modal = document.at_css('#map-modal[data-modal]')

    expect(trigger).to be_present
    expect(modal).to be_present
    expect(modal.has_attribute?("hidden")).to be(true)
    expect(modal.at_css("[data-modal-close]")).to be_present
    expect(modal.at_css(".site-modal__close")["aria-label"]).to eq(I18n.t("ui.common.close_dialog"))
    expect(modal.at_css(".site-modal__dialog")["tabindex"]).to eq("-1")
    expect(document.css("iframe").map { |frame| frame["title"] }).to all(eq(I18n.t("contact_us.where_we_are")))
    expect(document.css("iframe").map { |frame| frame["tabindex"] }).to all(eq("-1"))
    expect(document.css("iframe").map { |frame| frame["loading"] }).to all(eq("lazy"))
  end

  it "uses the shared modal contract on the registration page" do
    get new_user_registration_path

    expect(response).to have_http_status(:ok)

    document = Nokogiri::HTML.parse(response.body)
    trigger = document.at_css('[data-modal-trigger="registration-explainer"]')
    modal = document.at_css('#registration-explainer[data-modal]')

    expect(trigger).to be_present
    expect(modal).to be_present
    expect(modal.has_attribute?("hidden")).to be(true)
    expect(modal["aria-modal"]).to eq("true")
  end
end
