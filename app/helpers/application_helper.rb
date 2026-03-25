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

  def admin_nav_link_to(name, path, **options)
    classes = [options.delete(:class), ("is-active" if current_page?(path))].compact.join(" ")
    link_to(name, path, **options.merge(class: classes))
  end

end
