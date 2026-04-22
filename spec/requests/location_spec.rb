require 'rails_helper'

describe "Location" do
  let!(:user) { FactoryBot.create(:user) }
  let!(:published_property) { FactoryBot.create(:property, listing_state: "published") }
  let!(:draft_property) { FactoryBot.create(:property, :draft) }

  describe "GET /location/:id" do
    it "returns ok for a publicly visible property" do
      get location_path(published_property)
      expect(response).to have_http_status(:ok)
    end

    it "raises RecordNotFound for a non-public property" do
      expect { get location_path(draft_property) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises RecordNotFound for a non-existent property" do
      expect { get location_path(id: 0) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
