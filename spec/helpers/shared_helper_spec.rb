require 'rails_helper'

RSpec.describe SharedHelper, type: :helper do
  (1..5).each do |index|
    describe "#hero_#{index}_image" do
      it "renders the homepage hero image with 1x and 2x sources" do
        markup = helper.public_send("hero_#{index}_image")

        expect(markup).to match(%r{src="/assets/hero_#{index}-[^"]+\.jpg"})
        expect(markup).to match(%r{srcset="/assets/hero_#{index}-[^"]+\.jpg 1x, /assets/hero_#{index}@2x-[^"]+\.jpg 2x"})
      end
    end
  end

  describe "retina portrait helpers" do
    it "renders the world image with 1x and 2x sources" do
      markup = helper.world_image

      expect(markup).to match(%r{src="/assets/placeholder_world-[^"]+\.jpg"})
      expect(markup).to match(%r{srcset="/assets/placeholder_world-[^"]+\.jpg 1x, /assets/placeholder_world@2x-[^"]+\.jpg 2x"})
    end
  end

  describe "property placeholder helpers" do
    it "renders a small property placeholder with the provided class" do
      markup = helper.property_image_small(class_name: "listing-card__image")

      expect(markup).to include('alt="Property placeholder image"')
      expect(markup).to include('class="listing-card__image"')
      expect(markup).to include('width="160"')
      expect(markup).to include('height="160"')
    end

    it "renders a medium property placeholder" do
      markup = helper.property_image_medium

      expect(markup).to include('alt="Property placeholder image"')
      expect(markup).to include('width="250"')
      expect(markup).to include('height="250"')
    end
  end

  describe "formatting helpers" do
    let(:time) { Time.zone.local(2026, 3, 30, 14, 5) }

    it "formats times for the shared UI" do
      expect(helper.format_time(time)).to eq("March 30 2026, 14:05")
    end

    it "formats dates for the shared UI" do
      expect(helper.format_date(time)).to eq("30 March, 2026")
    end

    it "formats user names in title case" do
      user = User.new(first_name: "sTeVen", last_name: "hOBBs")

      expect(helper.format_name(user)).to eq("Steven Hobbs")
    end
  end
end
