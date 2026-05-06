require "rails_helper"

RSpec.describe "Public navigation", type: :system do
  it "shows the homepage header and language switcher options" do
    visit root_path

    expect(page).to have_title("GotTheKeys")
    within('[data-testid="site-header"]') do
      expect(page).to have_text("Property Platform")
    end
    expect(page).to have_text("Give buyers and tenants a polished website while giving QA teams a deterministic automation harness.")

    within('[data-testid="site-nav"]') do
      expect(page).to have_no_link("Home")
      expect(page).to have_no_link("Properties")
    end

    within('[data-testid="language-dropdown"]') do
      expect(page).to have_css(".language-dropdown__summary-code", text: "EN")
      expect(page).to have_css("summary .language-dropdown__flag")
      expect(page).to have_link("English", href: new_language_path(language: "en", return_to: "/"), visible: :all)
      expect(page).to have_link("Deutsch", href: new_language_path(language: "de", return_to: "/"), visible: :all)
      expect(page).to have_link("Français", href: new_language_path(language: "fr", return_to: "/"), visible: :all)
      expect(page).to have_link("Italiano", href: new_language_path(language: "it", return_to: "/"), visible: :all)
      expect(page).to have_link("中文", href: new_language_path(language: "zh", return_to: "/"), visible: :all)
    end
  end

  it "lets a visitor move through the main public navigation" do
    visit root_path

    click_link "For Sale"
    expect(page).to have_title("For Sale")
    expect(page).to have_text("Homes available to buy")

    click_link "For Rent"
    expect(page).to have_title("For Rent")
    expect(page).to have_text("Homes available to rent")

    click_link "Search"
    expect(page).to have_title("Search")
    expect(page).to have_text("Search sale and rental listings together")
  end
end
