require "rails_helper"

RSpec.describe "Photos", type: :request do
  let(:property) { FactoryBot.create(:property, address_line_1: "10 Willow Lane") }
  let(:owner) { property.user }

  it "prefills the first photo form as the primary image" do
    sign_in owner

    get property_photos_path(property)

    page = Nokogiri::HTML(response.body)
    primary_checkbox = page.at_css('input[type="checkbox"][name="photo[primary]"]')

    expect(response).to have_http_status(:ok)
    expect(primary_checkbox).to be_present
    expect(primary_checkbox["checked"]).to eq("checked")
  end
end
