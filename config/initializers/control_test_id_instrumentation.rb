# frozen_string_literal: true

module ControlTestIdInstrumentation
  module_function

  def sanitize(value)
    value.to_s
      .downcase
      .gsub(/[^a-z0-9]+/, "-")
      .gsub(/\A-+|-+\z/, "")
      .presence || "control"
  end

  def merge_data_testid(options, default)
    options = (options || {}).dup
    return options if options.key?("data-testid")

    data = (options[:data] || options["data"] || {}).dup
    return options if data.key?(:testid) || data.key?("testid") || data.key?(:test_id) || data.key?("test_id")

    data[:testid] = sanitize(default)
    options[:data] = data
    options
  end

  def object_control_testid(object_name, method, helper)
    sanitize([object_name, method, helper].compact.join("-"))
  end

  def tag_control_testid(name, helper)
    sanitize([name, helper].compact.join("-"))
  end

  def button_testid(label, helper = "button")
    sanitize([helper, label.presence || "control"].join("-"))
  end

  def form_testid(model: nil, scope: nil, url: nil, fallback: "form")
    source =
      scope.presence ||
      model_testid_source(model).presence ||
      url.presence ||
      fallback

    sanitize([source, "form"].join("-"))
  end

  def model_testid_source(model)
    record = model.is_a?(Array) ? model.compact.last : model
    return if record.blank?
    return record.model_name.param_key if record.respond_to?(:model_name)
    return record.class.model_name.param_key if record.respond_to?(:to_model) && record.class.respond_to?(:model_name)

    record.to_s
  end

  def button_link?(html_options)
    classes = html_options&.fetch(:class, nil).to_s.split
    classes.include?("button") || html_options&.dig(:role).to_s == "button" || html_options&.dig("role").to_s == "button"
  end
end

module ControlTestIdFormBuilder
  FIELD_HELPERS = %i[
    text_field password_field hidden_field file_field text_area textarea color_field search_field
    telephone_field phone_field date_field time_field datetime_field datetime_local_field month_field
    week_field url_field email_field number_field range_field
  ].freeze

  FIELD_HELPERS.each do |helper|
    define_method(helper) do |method, options = {}, *args|
      super(method, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.object_control_testid(object_name, method, helper)), *args)
    end
  end

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    super(method, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.object_control_testid(object_name, method, "checkbox")), checked_value, unchecked_value)
  end

  def radio_button(method, tag_value, options = {})
    super(method, tag_value, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.object_control_testid(object_name, "#{method}-#{tag_value}", "radio")))
  end

  def select(method, choices = nil, options = {}, html_options = {}, &block)
    super(method, choices, options, ControlTestIdInstrumentation.merge_data_testid(html_options, ControlTestIdInstrumentation.object_control_testid(object_name, method, "select")), &block)
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    super(method, collection, value_method, text_method, options, ControlTestIdInstrumentation.merge_data_testid(html_options, ControlTestIdInstrumentation.object_control_testid(object_name, method, "select")))
  end

  def submit(value = nil, options = {})
    super(value, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.button_testid("#{object_name}-#{value}", "submit")))
  end

  def button(value = nil, options = {}, &block)
    super(value, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.button_testid("#{object_name}-#{value}", "button")), &block)
  end
end

module ControlTestIdFormTagHelper
  FIELD_TAG_HELPERS = %i[
    text_field_tag password_field_tag hidden_field_tag file_field_tag text_area_tag textarea_tag
    color_field_tag search_field_tag telephone_field_tag phone_field_tag date_field_tag time_field_tag
    datetime_field_tag datetime_local_field_tag month_field_tag week_field_tag url_field_tag
    email_field_tag number_field_tag range_field_tag
  ].freeze

  FIELD_TAG_HELPERS.each do |helper|
    define_method(helper) do |name, value = nil, options = {}|
      super(name, value, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.tag_control_testid(name, helper)))
    end
  end

  def check_box_tag(name, value = "1", checked = false, options = {})
    super(name, value, checked, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.tag_control_testid(name, "checkbox")))
  end

  alias checkbox_tag check_box_tag

  def radio_button_tag(name, value, checked = false, options = {})
    super(name, value, checked, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.tag_control_testid("#{name}-#{value}", "radio")))
  end

  def select_tag(name, option_tags = nil, options = {})
    super(name, option_tags, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.tag_control_testid(name, "select")))
  end

  def submit_tag(value = "Save changes", options = {})
    super(value, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.button_testid(value, "submit")))
  end

  def image_submit_tag(source, options = {})
    super(source, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.button_testid(source, "image-submit")))
  end

  def button_tag(content_or_options = nil, options = nil, &block)
    if block_given?
      button_options = content_or_options.is_a?(Hash) ? content_or_options : (options || {})
      super(ControlTestIdInstrumentation.merge_data_testid(button_options, ControlTestIdInstrumentation.button_testid(button_options[:aria]&.fetch(:label, nil) || button_options["aria"]&.fetch("label", nil))), &block)
    else
      super(content_or_options, ControlTestIdInstrumentation.merge_data_testid(options || {}, ControlTestIdInstrumentation.button_testid(content_or_options)))
    end
  end

  def form_tag(url_for_options = {}, options = {}, &block)
    super(url_for_options, ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.form_testid(url: url_for_options, fallback: "tag")), &block)
  end
end

module ControlTestIdFormHelper
  def form_with(model: false, scope: nil, url: nil, format: nil, **options, &block)
    super(model:, scope:, url:, format:, **ControlTestIdInstrumentation.merge_data_testid(options, ControlTestIdInstrumentation.form_testid(model:, scope:, url:, fallback: "form-with")), &block)
  end

  def form_for(record, options = {}, &block)
    html_options = ControlTestIdInstrumentation.merge_data_testid(options.fetch(:html, {}), ControlTestIdInstrumentation.form_testid(model: record, fallback: "form-for"))
    super(record, options.merge(html: html_options), &block)
  end
end

module ControlTestIdUrlHelper
  def button_to(name = nil, options = nil, html_options = nil, &block)
    html_options = ControlTestIdInstrumentation.merge_data_testid(html_options || {}, ControlTestIdInstrumentation.button_testid(name || options, "button"))
    super(name, options, html_options, &block)
  end

  def link_to(name = nil, options = nil, html_options = nil, &block)
    if block_given?
      link_options = name
      link_html_options = options || {}
      link_html_options = ControlTestIdInstrumentation.merge_data_testid(link_html_options, ControlTestIdInstrumentation.button_testid(link_options, "link")) if ControlTestIdInstrumentation.button_link?(link_html_options)
      super(link_options, link_html_options, &block)
    else
      html_options = ControlTestIdInstrumentation.merge_data_testid(html_options || {}, ControlTestIdInstrumentation.button_testid(name, "link")) if ControlTestIdInstrumentation.button_link?(html_options || {})
      super(name, options, html_options)
    end
  end
end

ActiveSupport.on_load(:action_view) do
  ActionView::Helpers::FormBuilder.prepend(ControlTestIdFormBuilder)
  ActionView::Helpers::FormTagHelper.prepend(ControlTestIdFormTagHelper)
  ActionView::Helpers::FormHelper.prepend(ControlTestIdFormHelper)
  ActionView::Helpers::UrlHelper.prepend(ControlTestIdUrlHelper)
end
