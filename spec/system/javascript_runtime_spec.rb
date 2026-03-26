require "rails_helper"

RSpec.describe "JavaScript runtime", type: :system, js: true do
  it "boots the homepage carousel and shared modal end to end" do
    visit root_path

    expect(page).to have_css('[data-carousel-bullet][data-slide="0"][aria-current="true"]')
    expect(page).to have_css('[data-carousel-slide].is-active[aria-hidden="false"]', count: 1)
    expect(page).to have_css("[data-carousel-next]")

    page.execute_script("document.querySelector('[data-carousel-next]').click()")

    expect(page).to have_css('[data-carousel-bullet][data-slide="1"][aria-current="true"]')
    expect(page).to have_css('[data-carousel-slide].is-active[aria-hidden="false"]', count: 1)

    visit contact_us_path

    expect(page).to have_css('[data-modal-trigger="map-modal"][aria-controls="map-modal"][aria-expanded="false"][aria-haspopup="dialog"]')
    expect(page).to have_css("#map-modal[hidden][aria-hidden='true']", visible: false)

    click_button "View Map"

    expect(page).to have_css("#map-modal[aria-hidden='false']", visible: true)
    expect(page).to have_css("body.site-modal-open", visible: false)
    expect(page).to have_link("View Larger Map")

    find("body").send_keys(:escape)

    expect(page).to have_css("#map-modal[hidden][aria-hidden='true']", visible: false)
    expect(page).to have_no_css("body.site-modal-open", visible: false)
  end
end
