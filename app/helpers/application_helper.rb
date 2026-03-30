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

end
