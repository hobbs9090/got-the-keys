require 'rails_helper'

describe "For English language user" do

  describe "Viewing homepage" do

    it "shows page" do
      visit root_url

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
  end

  describe "Viewing Properties page" do

    it "shows page" do
      visit properties_url

      expect(page).to have_title("Properties")
      expect(page).to have_text("Property catalogue")
      expect(page).to have_css(".site-card.empty-state")
      expect(page).to have_text("No properties match this search")
    end
  end

  describe "Viewing For Sale page" do

    it "shows page" do
      visit for_sale_index_url

      expect(page).to have_title("For Sale")
      expect(page).to have_text("Homes available to buy")
      within(".page-hero") do
        expect(page).to have_no_css(".page-hero__brand")
      end
    end
  end

  describe "Viewing For Rent page" do

    it "shows page" do
      visit for_rent_index_url

      expect(page).to have_title("For Rent")
      expect(page).to have_text("Homes available to rent")
      within(".page-hero") do
        expect(page).to have_no_css(".page-hero__brand")
      end
    end
  end

  describe "Viewing Searches page" do

    it "shows page" do
      visit searches_url

      expect(page).to have_title("Search")
      expect(page).to have_text("Search listings and booking availability together")
    end
  end

  describe "Viewing Legal page" do

    it "shows page" do
      visit legal_index_path

      expect(page).to have_title("Legal")
      expect(page).to have_text("A plain-English summary of the key terms and responsibilities that apply when you use the site.")
    end
  end

  describe "Viewing Cookie Policy page" do

    it "shows page" do
      visit cookie_policy_index_url

      expect(page).to have_title("Cookie Policy")
      expect(page).to have_text("This site uses essential cookies to keep sign-in, forms, and language preferences working.")
    end
  end

  describe "Viewing How It Works page" do

    it "shows page" do
      visit how_it_works_url

      expect(page).to have_title("How It Works")
      expect(page).to have_text("How to market your home with more clarity and less fluff")
      expect(page).to have_css(".how-hero__badge", text: "Owner-led marketing")
      expect(page).to have_css(".how-timeline-card__badge", text: "01 Launch")
    end
  end

  describe "Viewing About Us page" do

    it "shows page" do
      visit about_us_url

      expect(page).to have_title("About Us")
      expect(page).to have_text("We built the service for owners who want clearer costs, better control, and a more direct route to serious enquiries.")
    end
  end

  describe "Viewing Contact Us page" do

    it "shows page" do
      visit contact_us_url

      expect(page).to have_title("Contact Us")
      expect(page).to have_text("Get in Touch!")
    end
  end

  describe "Viewing Blog page" do

    it "shows page" do
      visit blog_index_url

      expect(page).to have_title("Blog")
      expect(page).to have_text("Five Small Listing Improvements That Generate Better Enquiries")
    end
  end

  describe "Viewing Register page" do

    it "shows page" do
      visit new_user_registration_path

      expect(page).to have_title("Registration")
      expect(page).to have_text("Register")
      expect(page).to have_select(
        "Language",
        with_options: ["English", "Deutsch", "Français", "Italiano", "中文"]
      )
    end
  end

  describe "Viewing Sign in page" do

    it "shows page" do
      visit new_user_session_path

      expect(page).to have_title("Sign in")
      expect(page).to have_text("Sign in")
    end
  end

  describe "Viewing Sign as administrator in page" do

    it "shows page" do
      visit new_admin_session_path

      expect(page).to have_title("Sign in as Administrator")
      expect(page).to have_text("Sign in as Administrator")
    end
  end

  describe "Viewing Forgot your password page" do

    it "shows page" do
      visit 'http://localhost:3000/users/password/new'

      expect(page).to have_title("Forgot Password")
      expect(page).to have_text("Forgot Password")
    end
  end

# this test is only applicable for when :confirmable module is included
#describe "Viewing Resend confirmation instructions page" do
#
#  it "shows page" do
#    visit 'http://localhost:3000/users/confirmation/new'
#
#    expect(page).to have_text("Resend confirmation instructions")
#  end
#end

  describe "Viewing Resend unlock instructions page" do

    it "shows page" do
      visit 'http://localhost:3000/users/unlock/new'

      expect(page).to have_title("Resend unlock instructions")
      expect(page).to have_text("Resend unlock instructions")
    end

  end

end
