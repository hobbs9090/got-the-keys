require "rails_helper"

RSpec.describe "Cookie consent" do
  it "shows the banner until a visitor chooses essential-only cookies" do
    visit root_path

    expect(page).to have_text("We use cookies to run the site properly")
    click_button "Reject non-essential"

    expect(page).not_to have_text("We use cookies to run the site properly")

    visit root_path

    expect(page).not_to have_text("We use cookies to run the site properly")
  end

  it "lets a visitor revisit their choice from the cookie policy page" do
    visit root_path
    click_button "Accept all"

    visit cookie_policy_index_path

    expect(page).to have_text("Optional cookies accepted")
    click_button "Reject non-essential"

    expect(page).to have_text("Essential cookies only")
  end
end
