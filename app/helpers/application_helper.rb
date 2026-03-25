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

  def formatted_date_time(value)
    return if value.blank?

    l(value, format: :long)
  end

  def admin_nav_link_to(name, path, active: nil, **options)
    is_active = active.nil? ? current_page?(path) : active
    classes = [options.delete(:class), ("is-active" if is_active)].compact.join(" ")
    link_to(name, path, **options.merge(class: classes))
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

end
