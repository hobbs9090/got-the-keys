module ApplicationHelper

  def title(page_title, options={})
    content_for(:title, page_title.to_s)
    return content_tag(:h1, page_title, options)
  end

  def appointment_status_badge_class(status)
    {
      "pending" => "badge badge--warning",
      "confirmed" => "badge badge--success",
      "rescheduled" => "badge badge--accent",
      "cancelled" => "badge badge--muted",
      "completed" => "badge badge--neutral",
      "no_show" => "badge badge--danger"
    }.fetch(status.to_s, "badge")
  end

  def enquiry_status_badge_class(status)
    {
      "new" => "badge badge--warning",
      "contacted" => "badge badge--accent",
      "qualified" => "badge badge--success",
      "unqualified" => "badge badge--muted",
      "archived" => "badge badge--neutral"
    }.fetch(status.to_s, "badge")
  end

  def enquiry_source_label(source_type)
    I18n.t("ui.enquiries.source_types.#{source_type}", default: source_type.to_s.tr("_", " ").humanize)
  end

  def offer_status_badge_class(status)
    {
      "received" => "badge badge--warning",
      "accepted" => "badge badge--success",
      "rejected" => "badge badge--danger",
      "withdrawn" => "badge badge--muted",
      "completed" => "badge badge--neutral"
    }.fetch(status.to_s, "badge")
  end

  def rental_application_status_badge_class(status)
    {
      "received" => "badge badge--warning",
      "referencing" => "badge badge--accent",
      "approved" => "badge badge--success",
      "rejected" => "badge badge--danger",
      "withdrawn" => "badge badge--muted"
    }.fetch(status.to_s, "badge")
  end

  def formatted_date_time(value)
    return if value.blank?

    l(value, format: :long)
  end

  def formatted_calendar_date(value)
    return if value.blank?

    l(value.to_date, format: :calendar_heading)
  end

  def formatted_calendar_slot_summary(value)
    return if value.blank?

    "#{formatted_calendar_date(value)} \u00b7 #{l(value, format: :time_only)}"
  end

  def appointment_slot_picker_payload(slots)
    slots
      .group_by { |slot| slot.starts_at.to_date }
      .map do |date, day_slots|
        {
          key: date.iso8601,
          label: formatted_calendar_date(date),
          weekday: l(date, format: :calendar_day),
          day_number: l(date, format: "%d"),
          month_label: l(date, format: "%b"),
          times: day_slots.map do |slot|
            {
              value: slot.starts_at.iso8601,
              label: l(slot.starts_at, format: :time_only),
              finish_label: l(slot.ends_at, format: :time_only),
              group_viewing: slot.group_viewing
            }
          end
        }
      end
  end

  def appointment_slot_picker_calendar_months(picker_slots)
    return [] if picker_slots.blank?

    available_days = picker_slots.index_by { |day| Date.iso8601(day.fetch(:key)) }
    first_date = available_days.keys.min
    last_date = available_days.keys.max
    month_cursor = first_date.beginning_of_month
    months = []

    while month_cursor <= last_date.beginning_of_month
      month_start = month_cursor.beginning_of_month
      month_end = month_cursor.end_of_month
      leading_padding = (month_start.wday + 6) % 7
      trailing_padding = 6 - ((month_end.wday + 6) % 7)
      grid_start = month_start - leading_padding
      grid_end = month_end + trailing_padding

      months << {
        key: month_cursor.strftime("%Y-%m"),
        label: l(month_cursor, format: "%B %Y"),
        cells: (grid_start..grid_end).map do |date|
          day = available_days[date]

          {
            key: date.iso8601,
            label: l(date, format: :long),
            day_number: date.day,
            outside_month: date.month != month_cursor.month,
            available: day.present?
          }.merge(day || {})
        end
      }

      month_cursor = month_cursor.next_month.beginning_of_month
    end

    months
  end

  def monday_first_abbr_day_names
    I18n.t("date.abbr_day_names", default: Date::ABBR_DAYNAMES).rotate(1)
  end

  def admin_nav_link_to(name, path, active: nil, **options)
    is_active = active.nil? ? current_page?(path) : active
    classes = [options.delete(:class), ("is-active" if is_active)].compact.join(" ")
    options["aria-current"] = "page" if is_active
    link_to(name, path, **options.merge(class: classes))
  end

  def admin_dashboard_entry_path
    remembered_path = session[:last_admin_path].to_s
    return admin_root_path unless remembered_path.start_with?("/admin")

    remembered_path
  end

  def header_account_summary
    if admin_signed_in?
      {
        eyebrow: t("ui.site_header.account_eyebrow", default: "Signed in"),
        name: t("ui.site_header.admin_account_name", default: "Administrator"),
        detail: current_admin.email
      }
    elsif user_signed_in?
      {
        eyebrow: t("ui.site_header.account_eyebrow", default: "Signed in"),
        name: header_user_display_name(current_user),
        detail: current_user.email
      }
    end
  end

  def marketing_wordmark_tag(class_name: nil, alt: nil, decorative: false, variant: :default, **options)
    return theme_aware_marketing_wordmark_tag(class_name:, alt:, decorative:, **options) if variant.to_sym == :theme_aware

    image_options = {
      alt: decorative ? "" : (alt.presence || t("gotthekeys.gotthekeys", default: "got the keys")),
      class: ["marketing-wordmark", class_name].compact.join(" ")
    }

    if decorative
      image_options[:aria] = { hidden: true }
      image_options[:role] = "presentation"
    end

    image_tag(marketing_wordmark_asset_name(variant), **image_options.merge(options))
  end

  def theme_preference_storage_key
    "gotthekeys-theme-preference"
  end

  def theme_preference_options
    [
      [t("ui.theme_toggle.options.system", default: "System"), "system"],
      [t("ui.theme_toggle.options.light", default: "Light"), "light"],
      [t("ui.theme_toggle.options.dark", default: "Dark"), "dark"]
    ]
  end

  def theme_preference_bootstrap_script
    <<~JS
      (() => {
        const storageKey = #{theme_preference_storage_key.to_json};
        const validPreferences = new Set(["light", "dark", "system"]);
        let preference = "system";

        try {
          const storedPreference = window.localStorage.getItem(storageKey);
          if (validPreferences.has(storedPreference)) preference = storedPreference;
        } catch (_error) {
        }

        const prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
        const resolvedTheme = preference === "system" ? (prefersDark ? "dark" : "light") : preference;

        document.documentElement.dataset.themePreference = preference;
        document.documentElement.dataset.theme = resolvedTheme;
        document.documentElement.style.colorScheme = resolvedTheme;
      })();
    JS
  end

  def marketing_wordmark_asset_name(variant)
    case variant.to_sym
    when :dark
      "gotthekeys-wordmark-green-dark.svg"
    else
      "gotthekeys-wordmark-green.svg"
    end
  end

  def pixel_density_image_tag(source, retina_source: nil, **options)
    image_options = options.dup

    if retina_source.present?
      image_options[:srcset] = [
        "#{path_to_image(source)} 1x",
        "#{path_to_image(retina_source)} 2x"
      ].join(", ")
    end

    image_tag(source, **image_options)
  end

  def native_validation_messages
    {
      invalid: t("ui.validation.invalid"),
      required: t("ui.validation.required"),
      option_required: t("ui.validation.option_required"),
      checkbox_required: t("ui.validation.checkbox_required"),
      email: t("ui.validation.email"),
      url: t("ui.validation.url"),
      too_short: t("ui.validation.too_short", min: "__MIN__"),
      too_long: t("ui.validation.too_long", max: "__MAX__"),
      pattern: t("ui.validation.pattern"),
      number: t("ui.validation.number"),
      range_underflow: t("ui.validation.range_underflow", min: "__MIN__"),
      range_overflow: t("ui.validation.range_overflow", max: "__MAX__"),
      step: t("ui.validation.step")
    }
  end

  def form_control_options(object, attribute, classes: nil, **options)
    has_error = object.present? && object.errors[attribute].present?
    merged_classes = [classes, ("is-invalid-input" if has_error)].compact.join(" ").presence
    aria = options.delete(:aria).to_h

    if has_error
      aria[:invalid] = true
      aria[:describedby] = field_error_id(object, attribute)
    end

    options[:class] = merged_classes if merged_classes.present?
    options[:aria] = aria if aria.present?
    options
  end

  def form_label_options(object, attribute, classes: nil, **options)
    has_error = object.present? && object.errors[attribute].present?
    merged_classes = [classes, ("is-invalid-label" if has_error)].compact.join(" ").presence
    options[:class] = merged_classes if merged_classes.present?
    options
  end

  def field_error_messages(object, attribute)
    return if object.blank? || object.errors[attribute].blank?

    content_tag(
      :p,
      object.errors.full_messages_for(attribute).to_sentence,
      class: "form-error is-visible",
      id: field_error_id(object, attribute)
    )
  end

  def field_error_id(object, attribute)
    "#{object.model_name.singular}_#{attribute}_error"
  end

  def header_user_display_name(user)
    names = [user.first_name, user.last_name].filter_map { |value| value.to_s.strip.presence }.map(&:capitalize)
    names.join(" ").presence || t("ui.site_header.member_account_name", default: "Seller account")
  end

  private

  def theme_aware_marketing_wordmark_tag(class_name:, alt:, decorative:, **options)
    alt_text = alt.presence || t("gotthekeys.gotthekeys", default: "got the keys")

    wrapper_options = {
      class: "marketing-wordmark-stack marketing-wordmark-stack--theme-aware"
    }

    if decorative
      wrapper_options[:aria] = { hidden: true }
      wrapper_options[:role] = "presentation"
    else
      wrapper_options[:"aria-label"] = alt_text
      wrapper_options[:role] = "img"
    end

    image_options = options.merge(
      alt: "",
      aria: { hidden: true },
      role: "presentation"
    )

    light_wordmark = image_tag(
      marketing_wordmark_asset_name(:default),
      **image_options.merge(class: ["marketing-wordmark", class_name, "marketing-wordmark__asset", "marketing-wordmark__asset--light"].compact.join(" "))
    )
    dark_wordmark = image_tag(
      marketing_wordmark_asset_name(:dark),
      **image_options.merge(class: ["marketing-wordmark", class_name, "marketing-wordmark__asset", "marketing-wordmark__asset--dark"].compact.join(" "))
    )

    tag.span(safe_join([light_wordmark, dark_wordmark]), **wrapper_options)
  end

end
