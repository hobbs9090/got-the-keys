require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "app version helpers" do
    let(:version_config) { Rails.configuration.x.got_the_keys }

    around do |example|
      original_values = {
        version: version_config.version,
        build_sha: version_config.build_sha,
        build_number: version_config.build_number,
        deployed_at: version_config.deployed_at,
        deploy_target: version_config.deploy_target
      }

      example.run
    ensure
      version_config.version = original_values[:version]
      version_config.build_sha = original_values[:build_sha]
      version_config.build_number = original_values[:build_number]
      version_config.deployed_at = original_values[:deployed_at]
      version_config.deploy_target = original_values[:deploy_target]
    end

    it "formats the public app version from the semantic version" do
      version_config.version = "2.4.0"

      expect(helper.public_app_version).to eq("v2.4.0")
    end

    it "includes build metadata in the full app version when present" do
      version_config.version = "2.4.0"
      version_config.build_sha = "abc1234"
      version_config.build_number = "42"

      expect(helper.full_app_version).to eq("v2.4.0+abc1234.42")
    end

    it "omits blank build metadata cleanly" do
      version_config.version = "2.4.0"
      version_config.build_sha = nil
      version_config.build_number = ""

      expect(helper.full_app_version).to eq("v2.4.0")
    end
  end

  describe "#title" do
    it "stores the page title and returns a heading" do
      markup = helper.title("Dashboard", class: "page-title")

      expect(view.view_flow.get(:title).to_s).to eq("Dashboard")
      expect(markup).to include('<h1 class="page-title">Dashboard</h1>')
    end
  end

  describe "#page_meta_robots" do
    let(:seo_config) { Rails.configuration.x.got_the_keys }

    around do |example|
      original_public_indexing_enabled = seo_config.public_indexing_enabled
      original_public_indexing_env = ENV["PUBLIC_INDEXING_ENABLED"]
      original_allow_indexing_env = ENV["ALLOW_INDEXING"]

      example.run
    ensure
      seo_config.public_indexing_enabled = original_public_indexing_enabled
      ENV["PUBLIC_INDEXING_ENABLED"] = original_public_indexing_env
      ENV["ALLOW_INDEXING"] = original_allow_indexing_env
    end

    before do
      seo_config.public_indexing_enabled = false
      ENV.delete("PUBLIC_INDEXING_ENABLED")
      ENV.delete("ALLOW_INDEXING")
      allow(helper).to receive(:controller_path).and_return("welcome")
    end

    it "uses the environment-configured default for public pages" do
      seo_config.public_indexing_enabled = true

      expect(helper.page_meta_robots).to eq("index, follow")
    end

    it "lets PUBLIC_INDEXING_ENABLED override the environment default" do
      ENV["PUBLIC_INDEXING_ENABLED"] = "true"

      expect(helper.page_meta_robots).to eq("index, follow")
    end

    it "keeps admin pages noindex even when public indexing is enabled" do
      seo_config.public_indexing_enabled = true
      allow(helper).to receive(:controller_path).and_return("admin/properties")

      expect(helper.page_meta_robots).to eq("noindex, nofollow")
    end
  end

  describe "#appointment_status_badge_class" do
    it "maps known statuses to badge classes" do
      expect(helper.appointment_status_badge_class(:confirmed)).to eq("badge badge--success")
      expect(helper.appointment_status_badge_class("no_show")).to eq("badge badge--danger")
    end

    it "falls back to the default badge class for unknown statuses" do
      expect(helper.appointment_status_badge_class(:unknown)).to eq("badge")
    end
  end

  describe "#formatted_date_time" do
    it "returns a localized long timestamp in the configured zone for present values" do
      value = Time.zone.local(2026, 3, 30, 15, 45)
      zone_value = value.in_time_zone

      expect(helper.formatted_date_time(value)).to eq("#{I18n.l(zone_value, format: :long)} #{zone_value.zone}")
    end

    it "returns nil for blank values" do
      expect(helper.formatted_date_time(nil)).to be_nil
    end
  end

  describe "#formatted_public_date_time" do
    it "returns a localized long timestamp in the configured zone" do
      value = Time.zone.local(2026, 3, 30, 15, 45)
      zone_value = value.in_time_zone

      expect(helper.formatted_public_date_time(value)).to eq(I18n.l(zone_value, format: :long))
    end

    it "returns nil for blank values" do
      expect(helper.formatted_public_date_time(nil)).to be_nil
    end
  end

  describe "#formatted_calendar_date" do
    it "includes the weekday for selected calendar headings" do
      value = Date.new(2026, 4, 28)

      expect(helper.formatted_calendar_date(value)).to eq(I18n.l(value, format: :calendar_heading))
    end
  end

  describe "#display_number" do
    it "formats numbers with comma delimiters" do
      expect(helper.display_number(1234567)).to eq("1,234,567")
    end
  end

  describe "#appointment_slot_picker_calendar_months" do
    it "builds consecutive month grids across month boundaries" do
      picker_slots = [
        { key: "2026-04-28", label: "Tuesday, 28 April 2026", times: [{ value: "2026-04-28T09:00:00Z" }] },
        { key: "2026-05-02", label: "Saturday, 02 May 2026", times: [{ value: "2026-05-02T09:00:00Z" }] }
      ]

      months = helper.appointment_slot_picker_calendar_months(picker_slots)

      expect(months.map { |month| month.fetch(:key) }).to eq(%w[2026-04 2026-05])
      expect(months.first.fetch(:cells).any? { |cell| cell[:key] == "2026-04-28" && cell[:available] }).to be(true)
      expect(months.last.fetch(:cells).any? { |cell| cell[:key] == "2026-05-02" && cell[:available] }).to be(true)
    end
  end

  describe "#admin_nav_link_to" do
    it "adds the active class when the current page matches" do
      allow(helper).to receive(:current_page?).with("/admin/dashboard").and_return(true)

      markup = helper.admin_nav_link_to("Dashboard", "/admin/dashboard", class: "side-nav__link")

      expect(markup).to include('class="side-nav__link is-active"')
    end

    it "honors an explicit active override" do
      allow(helper).to receive(:current_page?).and_return(false)

      markup = helper.admin_nav_link_to("Appointments", "/admin/appointments", active: true)

      expect(markup).to include('class="is-active"')
    end
  end

  describe "#admin_dashboard_entry_path" do
    it "returns the remembered admin path when it stays inside the admin area" do
      helper.session[:last_admin_path] = "/admin/bookings?view=week"

      expect(helper.admin_dashboard_entry_path).to eq("/admin/bookings?view=week")
    end

    it "falls back to the dashboard when the remembered path is outside admin" do
      helper.session[:last_admin_path] = "/properties"

      expect(helper.admin_dashboard_entry_path).to eq(admin_root_path)
    end
  end

  describe "#marketing_wordmark_tag" do
    it "renders the translated alt text and default asset" do
      markup = helper.marketing_wordmark_tag(class_name: "brand-lockup")

      expect(markup).to match(%r{src="/assets/gotthekeys-wordmark-green-[^"]+\.svg"})
      expect(markup).to include('alt="GotTheKeys"')
      expect(markup).to include('class="marketing-wordmark brand-lockup"')
      expect(markup).to include('width="1600"')
      expect(markup).to include('height="360"')
    end

    it "derives the matching height when a custom width is provided" do
      markup = helper.marketing_wordmark_tag(width: 180)

      expect(markup).to include('width="180"')
      expect(markup).to include('height="41"')
    end

    it "renders decorative variants with presentation attributes" do
      markup = helper.marketing_wordmark_tag(decorative: true, variant: :dark)

      expect(markup).to match(%r{src="/assets/gotthekeys-wordmark-green-dark-[^"]+\.svg"})
      expect(markup).to include('alt=""')
      expect(markup).to include('aria-hidden="true"')
      expect(markup).to include('role="presentation"')
      expect(markup).to include('width="1600"')
      expect(markup).to include('height="360"')
    end
  end

  describe "#marketing_wordmark_asset_name" do
    it "returns the dark asset for the dark variant" do
      expect(helper.marketing_wordmark_asset_name(:dark)).to eq("gotthekeys-wordmark-green-dark.svg")
    end

    it "returns the default asset for all other variants" do
      expect(helper.marketing_wordmark_asset_name(:default)).to eq("gotthekeys-wordmark-green.svg")
      expect(helper.marketing_wordmark_asset_name(:light)).to eq("gotthekeys-wordmark-green.svg")
    end
  end

  describe "#pixel_density_image_tag" do
    it "includes a 1x and 2x srcset when a retina asset is provided" do
      markup = helper.pixel_density_image_tag("hero_1.webp", retina_source: "hero_1@2x.webp")

      expect(markup).to match(%r{src="/assets/hero_1-[^"]+\.webp"})
      expect(markup).to include('alt=""')
      expect(markup).to include('decoding="async"')
      expect(markup).to include('width="641"')
      expect(markup).to include('height="392"')
      expect(markup).to match(
        %r{srcset="/assets/hero_1-[^"]+\.webp 1x, /assets/hero_1@2x-[^"]+\.webp 2x"}
      )
    end

    it "renders a standard image without srcset when no retina asset is provided" do
      markup = helper.pixel_density_image_tag("hero_1.webp")

      expect(markup).to match(%r{src="/assets/hero_1-[^"]+\.webp"})
      expect(markup).to include('alt=""')
      expect(markup).to include('decoding="async"')
      expect(markup).to include('width="641"')
      expect(markup).to include('height="392"')
      expect(markup).not_to include("srcset=")
    end

    it "preserves an explicit alt when one is provided" do
      markup = helper.pixel_density_image_tag("hero_1.webp", alt: "Homepage hero")

      expect(markup).to include('alt="Homepage hero"')
    end

    it "preserves explicit loading and fetchpriority hints" do
      markup = helper.pixel_density_image_tag("hero_1.webp", loading: "lazy", fetchpriority: "low")

      expect(markup).to include('loading="lazy"')
      expect(markup).to include('fetchpriority="low"')
    end
  end

  describe "#native_validation_messages" do
    it "returns translated browser validation copy with interpolation tokens" do
      I18n.with_locale(:de) do
        expect(helper.native_validation_messages).to include(
          invalid: "Bitte geben Sie einen gültigen Wert ein.",
          required: "Bitte füllen Sie dieses Feld aus.",
          too_short: "Bitte verwenden Sie mindestens __MIN__ Zeichen.",
          range_overflow: "Bitte geben Sie einen Wert kleiner oder gleich __MAX__ ein."
        )
      end
    end
  end

  describe "#form_control_options" do
    it "adds invalid classes and aria metadata when the field has errors" do
      property = Property.new
      property.errors.add(:address_line_1, "can't be blank")

      options = helper.form_control_options(
        property,
        :address_line_1,
        classes: "text-input",
        aria: { label: "Address line 1" }
      )

      expect(options[:class]).to eq("text-input is-invalid-input")
      expect(options[:aria]).to eq(
        label: "Address line 1",
        invalid: true,
        describedby: "property_address_line_1_error"
      )
    end

    it "leaves clean fields unchanged" do
      property = Property.new

      expect(helper.form_control_options(property, :address_line_1, classes: "text-input")).to eq(class: "text-input")
    end
  end

  describe "#form_label_options" do
    it "adds the invalid label class when the field has errors" do
      property = Property.new
      property.errors.add(:address_line_1, "can't be blank")

      expect(helper.form_label_options(property, :address_line_1, classes: "form-label")).to eq(
        class: "form-label is-invalid-label"
      )
    end
  end

  describe "#field_error_messages" do
    it "renders the full message and field error id" do
      property = Property.new
      property.errors.add(:address_line_1, "can't be blank")

      markup = helper.field_error_messages(property, :address_line_1)

      expect(markup).to include("Address line 1 can&#39;t be blank")
      expect(markup).to include('class="form-error is-visible"')
      expect(markup).to include('id="property_address_line_1_error"')
    end

    it "returns nil when there are no field errors" do
      expect(helper.field_error_messages(Property.new, :address_line_1)).to be_nil
    end
  end

  describe "#field_error_id" do
    it "builds a predictable error element id" do
      expect(helper.field_error_id(Property.new, :address_line_1)).to eq("property_address_line_1_error")
    end
  end
end
