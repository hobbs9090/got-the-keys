require "prawn"
require "tempfile"

class PropertyDocumentPayloadBuilder
  include ActionView::Helpers::NumberHelper

  PAGE_WIDTH    = 612
  PAGE_HEIGHT   = 792
  MARGIN        = 36
  CONTENT_WIDTH = PAGE_WIDTH - (MARGIN * 2)

  COLORS = {
    page_background:  "F6F9FD",
    panel_background: "FFFFFF",
    panel_border:     "D7E3EF",
    brand_blue:       "3D69E8",
    brand_green:      "22C55E",
    dark_text:        "173155",
    body_text:        "33425D",
    muted_text:       "6B7D9E",
    soft_blue:        "EEF5FF",
    soft_green:       "E8F7EC",
    hero_image_bg:    "F2F7FD",
    contact_bg:       "10213F",
    white:            "FFFFFF"
  }.freeze

  def initialize(document:, property:)
    @document = document
    @property = property
  end

  def payload
    pdf_file? ? pdf_payload : text_payload
  end

  private

  attr_reader :document, :property

  def pdf_file?
    File.extname(document.file_name).casecmp(".pdf").zero?
  end

  def pdf_payload
    Prawn::Fonts::AFM.hide_m17n_warning = true
    pdf = Prawn::Document.new(page_size: [PAGE_WIDTH, PAGE_HEIGHT], margin: 0)
    render_page(pdf)
    pdf.render
  end

  def render_page(pdf)
    layout = compute_layout
    filled_rect(pdf, 0, 0, PAGE_WIDTH, PAGE_HEIGHT, :page_background)
    panel(pdf, MARGIN, 430, CONTENT_WIDTH, 308)
    panel(pdf, MARGIN, 58, CONTENT_WIDTH, 348)
    draw_brand(pdf, 56, 693)
    draw_document_badge(pdf, 408, 697)
    draw_sale_status_badge(pdf, 56, 657)
    draw_header_copy(pdf, 56, 652, layout)
    draw_price(pdf, 56, layout[:price_y])
    draw_header_meta(pdf, 56, layout)
    draw_hero_image_panel(pdf, 318, 520, 236, (236 / 1.5).round)
    draw_overview(pdf, 56, 382)
    draw_key_facts(pdf, 382, 382)
    draw_contact_strip(pdf, 56, 88, 500, 64)
  end

  # --- Drawing primitives ---

  def filled_rect(pdf, x, y, w, h, color_key)
    pdf.fill_color COLORS.fetch(color_key)
    pdf.fill_rectangle [x, y + h], w, h
  end

  def stroked_rect(pdf, x, y, w, h, color_key, lw: 1.2)
    pdf.stroke_color COLORS.fetch(color_key)
    pdf.line_width lw
    pdf.stroke_rectangle [x, y + h], w, h
  end

  def panel(pdf, x, y, w, h)
    filled_rect(pdf, x, y, w, h, :panel_background)
    stroked_rect(pdf, x, y, w, h, :panel_border)
  end

  def text_at(pdf, str, x, y, size:, color:, bold: false)
    font_name = bold ? "Helvetica-Bold" : "Helvetica"
    # ISO-8859-1 encoding bypasses Prawn's UTF-8 hex path, producing (text) Tj literals
    safe_str = sanitize_text(str).encode("ISO-8859-1", invalid: :replace, undef: :replace, replace: "?")
    pdf.fill_color COLORS.fetch(color)
    pdf.font(font_name) { pdf.draw_text safe_str, at: [x, y], size: size, kerning: false }
  end

  # --- Layout sections ---

  def draw_brand(pdf, x, y)
    ix = x
    iy = y - 8
    filled_rect(pdf, ix, iy, 28, 28, :soft_blue)
    stroked_rect(pdf, ix, iy, 28, 28, :panel_border)
    pdf.stroke_color COLORS[:dark_text]
    pdf.line_width 2
    [[ix + 6,  iy + 14, ix + 14, iy + 21],
     [ix + 14, iy + 21, ix + 22, iy + 14],
     [ix + 8,  iy + 14, ix + 8,  iy + 6],
     [ix + 20, iy + 14, ix + 20, iy + 6],
     [ix + 8,  iy + 6,  ix + 20, iy + 6]].each do |(x1, y1, x2, y2)|
      pdf.stroke_line [x1, y1], [x2, y2]
    end
    filled_rect(pdf, ix + 11, iy + 6, 6, 6, :soft_green)
    text_at(pdf, "PROPERTY PLATFORM", x + 38, y + 14, size: 9,  color: :brand_blue,  bold: true)
    text_at(pdf, "got",               x + 38, y,      size: 21, color: :dark_text,   bold: true)
    text_at(pdf, "thekeys",           x + 76, y,      size: 21, color: :brand_green, bold: true)
  end

  def draw_document_badge(pdf, x, y)
    label = sanitize_text((document.title.presence || document.category_label).upcase)
    width = [label.length * 10 * 0.58 + 18, 108].max.round
    filled_rect(pdf, x, y, width, 22, :soft_blue)
    stroked_rect(pdf, x, y, width, 22, :panel_border, lw: 1)
    text_at(pdf, label, x + 9, y + 6, size: 10, color: :brand_blue, bold: true)
  end

  def draw_sale_status_badge(pdf, x, y)
    for_rent = property.sale_status == Property::SALE_STATUSES[:for_rent]
    label = for_rent ? "FOR RENT" : "FOR SALE"
    fill  = for_rent ? :soft_green : :soft_blue
    color = for_rent ? :brand_green : :brand_blue
    filled_rect(pdf, x, y, 84, 20, fill)
    text_at(pdf, label, x + 10, y + 5, size: 10, color: color, bold: true)
  end

  def draw_header_copy(pdf, x, y, layout)
    eyebrow = "#{property.property_type} in #{property.location_line}"
    text_at(pdf, eyebrow, x, y, size: 10, color: :brand_blue, bold: true)
    line_y = y - 34
    layout[:address_lines].each do |line|
      text_at(pdf, line, x, line_y, size: 22, color: :dark_text, bold: true)
      line_y -= 24
    end
    layout[:headline_lines].each do |line|
      text_at(pdf, line, x, line_y - 6, size: 13, color: :body_text)
      line_y -= 16
    end
  end

  def draw_price(pdf, x, y)
    text_at(pdf, "Guide price", x, y + 32, size: 9.5, color: :brand_blue, bold: true)
    text_at(pdf, formatted_currency(property.asking_price), x, y, size: 28, color: :dark_text, bold: true)
  end

  def draw_header_meta(pdf, x, layout)
    text_at(pdf, hero_meta_line, x, layout[:hero_meta_y], size: 10.5, color: :muted_text)
    return if chronology_line.blank?

    text_at(pdf, chronology_line, x, layout[:chronology_y], size: 10.5, color: :muted_text)
  end

  def draw_hero_image_panel(pdf, x, y, w, h)
    filled_rect(pdf, x, y, w, h, :hero_image_bg)
    stroked_rect(pdf, x, y, w, h, :panel_border, lw: 1)
    if embed_hero_image(pdf, x, y, w, h)
      text_at(pdf, "Primary property image", x + 10, y - 18, size: 10, color: :muted_text)
    else
      text_at(pdf, "Image coming soon",   x + 58, y + (h / 2) - 8,  size: 14, color: :brand_blue, bold: true)
      text_at(pdf, "This sheet will use the listing hero image once it is attached.", x + 24, y + (h / 2) - 30, size: 10, color: :muted_text)
    end
  end

  def embed_hero_image(pdf, x, y, w, h)
    path = hero_image_path
    return false unless path

    embedded = false
    image_file_for(path) do |image_path|
      pdf.image image_path, at: [x, y + h], fit: [w, h]
      embedded = true
    end
    embedded
  end

  def image_file_for(path)
    case path.extname.downcase
    when ".jpg", ".jpeg", ".png"
      yield path.to_s
    when ".webp"
      tmp = convert_webp_to_png(path)
      return unless tmp
      begin
        yield tmp.path
      ensure
        tmp.close!
      end
    end
  end

  def draw_overview(pdf, x, y)
    text_at(pdf, "Overview", x, y, size: 13, color: :dark_text, bold: true)
    description = property.property_description.to_s.squish.truncate(460, omission: "...")
    current_y = y - 26
    wrap_text(description, 286, 11.5, false, 10).each do |line|
      text_at(pdf, line, x, current_y, size: 11.5, color: :body_text)
      current_y -= 17
    end
    text_at(pdf, "Prepared #{Date.current.strftime('%d %B %Y')}", x, 172, size: 10, color: :muted_text)
    text_at(pdf, "www.gotthekeys.uk",                            x, 156, size: 10, color: :brand_blue, bold: true)
  end

  def draw_key_facts(pdf, x, y)
    text_at(pdf, "Key facts", x, y, size: 13, color: :dark_text, bold: true)
    facts_for_sheet.each_with_index do |(label, value), index|
      row_y = y - 28 - (index * 30)
      text_at(pdf, label.upcase, x, row_y,      size: 8.5, color: :muted_text, bold: true)
      text_at(pdf, value.to_s,   x, row_y - 12, size: 11,  color: :dark_text,  bold: true)
    end
  end

  def draw_contact_strip(pdf, x, y, w, h)
    branch = AppSettings.primary_branch_profile
    filled_rect(pdf, x, y, w, h, :contact_bg)
    text_at(pdf, branch.fetch(:name),                                   x + 16,  y + 33, size: 14, color: :white, bold: true)
    text_at(pdf, "#{branch.fetch(:phone)}  |  #{branch.fetch(:email)}", x + 214, y + 26, size: 10, color: :white)
  end

  # --- Layout computation ---

  def compute_layout
    address_lines  = wrap_text(property.address_line_1, 238, 22, true,  2)
    headline_lines = wrap_text(property.headline,       238, 13, false, 3)
    address_bottom_y  = 652 - 34 - (24 * address_lines.length)
    headline_bottom_y = address_bottom_y - (16 * headline_lines.length)
    price_y           = [headline_bottom_y - 42, 522].min
    hero_meta_y       = price_y - 58
    chronology_y      = hero_meta_y - 17
    { address_lines:, headline_lines:, price_y:, hero_meta_y:, chronology_y: }
  end

  def hero_meta_line
    [
      bedrooms_label,
      "#{property.bathrooms} bath#{'s' unless property.bathrooms.to_i == 1}",
      property.town_city
    ].compact.join("  |  ")
  end

  def chronology_line
    parts = []
    parts << "Updated #{property.refurbished_year}" if property.refurbished_year.present?
    parts << area_label if area_label.present?
    parts.compact.join("  |  ")
  end

  def facts_for_sheet
    [
      ["Price",    formatted_currency(property.asking_price)],
      ["Bedrooms", bedrooms_label],
      ["Bathrooms", property.bathrooms.to_i.to_s],
      ["Town",     property.town_city],
      ["Postcode", property.postcode],
      ["Type",     property.property_type],
      ["Area",     area_label],
      ["Updated",  property.refurbished_year&.to_s],
      ["Available", availability_label],
      ["Tenure",   property.tenure],
      ["Parking",  property.parking]
    ].select { |_label, value| value.present? }.first(8)
  end

  def bedrooms_label
    property.bedrooms.to_i.zero? ? "Studio" : "#{property.bedrooms} bedroom#{'s' unless property.bedrooms.to_i == 1}"
  end

  def area_label
    "#{property.floor_area_sq_ft} sq ft" if property.floor_area_sq_ft.present?
  end

  def availability_label
    property.available_from.present? ? property.available_from.strftime("%d %b %Y") : "Available now"
  end

  def formatted_currency(amount)
    number_to_currency(amount, unit: "£", precision: 0)
  end

  # --- Image helpers ---

  def hero_image_path
    image_name = property.hero_image_name.to_s
    return if image_name.blank?

    [retina_variant_name(image_name), image_name]
      .compact
      .flat_map { |name| image_path_candidates(name) }
      .find(&:exist?)
  end

  def image_path_candidates(image_name)
    normalized_name = image_name.to_s.delete_prefix("/")

    if normalized_name.start_with?("uploads/")
      [public_upload_path(normalized_name)].compact
    else
      [Rails.root.join("app/assets/images", normalized_name)]
    end
  end

  def public_upload_path(normalized_name)
    root = Rails.env.test? ? Rails.root.join("tmp", "uploads") : Rails.root.join("public", "uploads")
    relative_upload_path = normalized_name.delete_prefix("uploads/")
    candidate = root.join(relative_upload_path)
    return unless candidate.expand_path.to_s.start_with?(root.expand_path.to_s)

    candidate
  end

  def retina_variant_name(image_name)
    ext = File.extname(image_name)
    return if ext.blank?

    image_name.sub(/#{Regexp.escape(ext)}\z/i, "@2x#{ext}")
  end

  def convert_webp_to_png(path)
    tmp = Tempfile.new(["property-doc-image", ".png"])
    tmp.close
    system("dwebp", path.to_s, "-quiet", "-o", tmp.path) ? tmp : (tmp.unlink; nil)
  end

  # --- Text helpers ---

  def sanitize_text(text)
    I18n.transliterate(text.to_s.gsub("£", "__P__")).gsub("__P__", "£")
  end

  def wrap_text(text, width, font_size, bold, max_lines)
    words = sanitize_text(text).split(/\s+/)
    return [""] if words.empty?

    factor    = bold ? 0.58 : 0.52
    max_chars = [(width / (font_size * factor)).floor, 8].max
    lines     = []
    current   = +""

    words.each do |word|
      candidate = current.blank? ? word : "#{current} #{word}"
      if candidate.length <= max_chars
        current = candidate
      else
        lines << current if current.present?
        current = word
      end
    end
    lines << current if current.present?

    if lines.length > max_lines
      lines = lines.first(max_lines)
      lines[-1] = lines.last.truncate(max_chars, omission: "...")
    end

    lines
  end

  def text_payload
    <<~TEXT
      GotTheKeys document download

      Title: #{document.title}
      Category: #{document.category_label}
      Property: #{property.address_line_1}
      Visibility: #{document.visibility}
    TEXT
  end
end
