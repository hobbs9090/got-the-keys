module DeviseHelper
  # Keep Devise error rendering in one helper so legacy forms can share it.
  def devise_error_messages!
    return "" if resource.errors.empty?

    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    sentence = I18n.t(
      "errors.messages.not_saved",
      count: resource.errors.count,
      resource: resource.class.model_name.human.downcase
    )

    html = <<-HTML
    <section id="errors">
      <div id="error_explanation errors">
        <h2>#{sentence}</h2>
        <ul>#{messages}</ul>
      </div>
      </section>
    HTML

    html.html_safe
  end
end
