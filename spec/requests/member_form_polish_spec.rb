require "rails_helper"

RSpec.describe "Member form polish" do
  let(:user) { FactoryBot.create(:user, email: "nina.hughes@example.com") }

  before { sign_in user }

  it "shows a linked account email display and UK phone hint on offer forms" do
    property = FactoryBot.create(:property)

    get new_property_offer_path(property)

    document = Nokogiri::HTML(response.body)

    expect(document.at_css('[data-testid="offer-buyer-email-display"]').text).to include(user.email)
    expect(document.at_css('input[name="offer[buyer_email]"][type="hidden"]')["value"]).to eq(user.email)
    expect(document.at_css('input[name="offer[buyer_phone]"]')["pattern"]).to include("+44")
    expect(response.body).to include(I18n.t("ui.validation.phone_number_hint"))
  end

  it "limits buyer-facing enquiry types by listing mode" do
    sale = FactoryBot.create(:property)
    rental = FactoryBot.create(:property, :for_rent)

    get new_property_enquiry_path(sale)
    sale_options = Nokogiri::HTML(response.body).css("#enquiry_source_type option").map(&:text)

    expect(sale_options).to contain_exactly("General enquiry", "Brochure request", "Make an offer enquiry")

    get new_property_enquiry_path(rental)
    rental_options = Nokogiri::HTML(response.body).css("#enquiry_source_type option").map(&:text)

    expect(rental_options).to contain_exactly("General enquiry", "Letting enquiry", "Application question")
  end

  it "renders registration password strength feedback and a 10 character minimum" do
    sign_out user

    get new_user_registration_path

    document = Nokogiri::HTML(response.body)
    password = document.at_css('input[name="user[password]"]')

    expect(password["minlength"]).to eq("10")
    expect(document.at_css('[data-testid="registration-password-strength"]')).to be_present
  end
end
