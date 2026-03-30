require "rails_helper"

RSpec.describe "JavaScript runtime", type: :system, js: true do
  def sign_in_as_user(user, password: "changeme")
    visit new_user_session_path

    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button "Sign in"
  end

  it "boots the homepage carousel and shared modal end to end" do
    visit root_path

    find("body").send_keys(:tab)

    expect(page).to have_css("a.skip-link:focus", wait: 5)

    find("body").send_keys(:enter)

    expect(page).to have_css("main#main-content:focus", wait: 5)
    expect(page).to have_no_css("a.skip-link:focus", wait: 5)
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

  it "toggles the furnishing field based on the selected sale status" do
    user = FactoryBot.create(:user, email: "listing-user@example.com", password: "changeme", password_confirmation: "changeme")

    sign_in_as_user(user)
    visit new_property_path

    expect(page).to have_css("[data-property-furnishing-field][hidden]", visible: false)

    select "For Rent", from: "property_sale_status"

    expect(page).to have_no_css("[data-property-furnishing-field][hidden]", visible: false)
    expect(page.evaluate_script("document.getElementById('property_furnishing').disabled")).to be(false)

    select "For Sale", from: "property_sale_status"

    expect(page).to have_css("[data-property-furnishing-field][hidden]", visible: false)
    expect(page.evaluate_script("document.getElementById('property_furnishing').disabled")).to be(true)
  end
end
