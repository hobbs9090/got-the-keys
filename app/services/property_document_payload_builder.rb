require "chunky_png"
require "tempfile"
require "zlib"

class PropertyDocumentPayloadBuilder
  include ActionView::Helpers::NumberHelper

  PAGE_WIDTH = 612.0
  PAGE_HEIGHT = 792.0
  MARGIN = 36.0
  CONTENT_WIDTH = PAGE_WIDTH - (MARGIN * 2)
  HERO_CARD_Y = 430.0
  HERO_CARD_HEIGHT = 308.0
  DETAILS_CARD_Y = 58.0
  DETAILS_CARD_HEIGHT = 348.0
  IMAGE_BOX_WIDTH = 236.0
  IMAGE_BOX_HEIGHT = (IMAGE_BOX_WIDTH / 1.5).round(2)
  CONTACT_STRIP_Y = 88.0
  CONTACT_STRIP_HEIGHT = 64.0
  POUND_PLACEHOLDER = "__POUND__".freeze

  COLORS = {
    page_background: [0.965, 0.976, 0.992],
    panel_background: [1.0, 1.0, 1.0],
    panel_border: [0.843, 0.89, 0.937],
    brand_blue: [0.239, 0.412, 0.91],
    brand_green: [0.133, 0.773, 0.369],
    dark_text: [0.09, 0.192, 0.333],
    body_text: [0.2, 0.258, 0.365],
    muted_text: [0.42, 0.49, 0.62],
    soft_blue: [0.933, 0.961, 1.0],
    soft_green: [0.91, 0.969, 0.925],
    hero_image_background: [0.949, 0.969, 0.992],
    contact_background: [0.063, 0.129, 0.247],
    white: [1.0, 1.0, 1.0]
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
    hero_image = hero_image_asset
    image_ref = hero_image.present? ? 7 : nil
    page_resources = build_page_resources(image_ref:)
    page_content = build_page_content(hero_image:)

    objects = [
      "<< /Type /Catalog /Pages 2 0 R >>",
      "<< /Type /Pages /Count 1 /Kids [3 0 R] >>",
      "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 #{fmt(PAGE_WIDTH)} #{fmt(PAGE_HEIGHT)}] /Contents 4 0 R /Resources #{page_resources} >>",
      stream_object(page_content),
      "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
      "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>"
    ]
    objects << image_object(hero_image) if hero_image.present?

    build_pdf(objects)
  end

  def build_page_resources(image_ref:)
    resources = +"<< /Font << /F1 5 0 R /F2 6 0 R >>"
    proc_sets = ["/PDF", "/Text"]

    if image_ref.present?
      resources << " /XObject << /Im1 #{image_ref} 0 R >>"
      proc_sets << "/ImageB"
      proc_sets << "/ImageC"
      proc_sets << "/ImageI"
    end

    resources << " /ProcSet [#{proc_sets.join(' ')}] >>"
    resources
  end

  def build_page_content(hero_image:)
    commands = []

    draw_filled_rect(commands, x: 0, y: 0, width: PAGE_WIDTH, height: PAGE_HEIGHT, fill: COLORS[:page_background])
    draw_panel(commands, x: MARGIN, y: HERO_CARD_Y, width: CONTENT_WIDTH, height: HERO_CARD_HEIGHT)
    draw_panel(commands, x: MARGIN, y: DETAILS_CARD_Y, width: CONTENT_WIDTH, height: DETAILS_CARD_HEIGHT)

    layout = header_layout

    draw_brand(commands, x: 56, y: 693)
    draw_document_badge(commands, x: 408, y: 697)
    draw_sale_status_badge(commands, x: 56, y: 657)
    draw_header_copy(commands, x: 56, y: 652, layout:)
    draw_price(commands, x: 56, y: layout.fetch(:price_y))
    draw_header_meta(commands, x: 56, layout:)
    draw_hero_image_panel(commands, hero_image:, x: 318, y: 520, width: IMAGE_BOX_WIDTH, height: IMAGE_BOX_HEIGHT)
    draw_overview(commands, x: 56, y: 382)
    draw_key_facts(commands, x: 382, y: 382)
    draw_contact_strip(commands, x: 56, y: CONTACT_STRIP_Y, width: 500, height: CONTACT_STRIP_HEIGHT)

    commands.join
  end

  def build_pdf(objects)
    pdf = +"%PDF-1.4\n".b
    offsets = [0]

    objects.each_with_index do |object, index|
      body = object.to_s.b
      offsets << pdf.bytesize
      pdf << "#{index + 1} 0 obj\n".b
      pdf << body
      pdf << "\nendobj\n".b
    end

    xref_offset = pdf.bytesize
    pdf << "xref\n0 #{objects.length + 1}\n".b
    pdf << "0000000000 65535 f \n".b

    offsets.drop(1).each do |offset|
      pdf << format("%010d 00000 n \n", offset).b
    end

    pdf << "trailer\n<< /Root 1 0 R /Size #{objects.length + 1} >>\n".b
    pdf << "startxref\n#{xref_offset}\n%%EOF\n".b
    pdf
  end

  def stream_object(content)
    bytes = content.to_s.b
    "<< /Length #{bytes.bytesize} >>\nstream\n#{bytes}\nendstream".b
  end

  def image_object(image)
    <<~PDF.b
      << /Type /XObject
         /Subtype /Image
         /Width #{image.fetch(:width)}
         /Height #{image.fetch(:height)}
         /ColorSpace /DeviceRGB
         /BitsPerComponent 8
         /Filter #{image.fetch(:filter)}
         /Length #{image.fetch(:data).bytesize}
      >>
      stream
      #{image.fetch(:data)}
      endstream
    PDF
  end

  def draw_panel(commands, x:, y:, width:, height:)
    draw_filled_rect(commands, x:, y:, width:, height:, fill: COLORS[:panel_background])
    draw_stroked_rect(commands, x:, y:, width:, height:, stroke: COLORS[:panel_border], line_width: 1.2)
  end

  def draw_brand(commands, x:, y:)
    draw_brand_icon(commands, x:, y: y - 8)
    draw_text(commands, "PROPERTY PLATFORM", x: x + 38, y: y + 14, size: 9, font: :bold, color: COLORS[:brand_blue])
    draw_text(commands, "got", x: x + 38, y:, size: 21, font: :bold, color: COLORS[:dark_text])
    draw_text(commands, "thekeys", x: x + 76, y:, size: 21, font: :bold, color: COLORS[:brand_green])
  end

  def draw_brand_icon(commands, x:, y:)
    draw_filled_rect(commands, x:, y:, width: 28, height: 28, fill: COLORS[:soft_blue])
    draw_stroked_rect(commands, x:, y:, width: 28, height: 28, stroke: COLORS[:panel_border], line_width: 1.2)
    draw_line(commands, x1: x + 6, y1: y + 14, x2: x + 14, y2: y + 21, color: COLORS[:dark_text], line_width: 2)
    draw_line(commands, x1: x + 14, y1: y + 21, x2: x + 22, y2: y + 14, color: COLORS[:dark_text], line_width: 2)
    draw_line(commands, x1: x + 8, y1: y + 14, x2: x + 8, y2: y + 6, color: COLORS[:dark_text], line_width: 2)
    draw_line(commands, x1: x + 20, y1: y + 14, x2: x + 20, y2: y + 6, color: COLORS[:dark_text], line_width: 2)
    draw_line(commands, x1: x + 8, y1: y + 6, x2: x + 20, y2: y + 6, color: COLORS[:dark_text], line_width: 2)
    draw_filled_rect(commands, x: x + 11, y: y + 6, width: 6, height: 6, fill: COLORS[:soft_green])
  end

  def draw_document_badge(commands, x:, y:)
    label = pdf_text(document.title.presence || document.category_label).upcase
    width = [text_width(label, 10, :bold) + 18, 108].max

    draw_filled_rect(commands, x:, y:, width:, height: 22, fill: COLORS[:soft_blue])
    draw_stroked_rect(commands, x:, y:, width:, height: 22, stroke: COLORS[:panel_border], line_width: 1)
    draw_text(commands, label, x: x + 9, y: y + 6, size: 10, font: :bold, color: COLORS[:brand_blue])
  end

  def draw_sale_status_badge(commands, x:, y:)
    sale_status = property.sale_status == Property::SALE_STATUSES[:for_rent] ? "FOR RENT" : "FOR SALE"
    fill = property.sale_status == Property::SALE_STATUSES[:for_rent] ? COLORS[:soft_green] : COLORS[:soft_blue]
    color = property.sale_status == Property::SALE_STATUSES[:for_rent] ? COLORS[:brand_green] : COLORS[:brand_blue]
    width = 84

    draw_filled_rect(commands, x:, y:, width:, height: 20, fill:)
    draw_text(commands, sale_status, x: x + 10, y: y + 5, size: 10, font: :bold, color:)
  end

  def draw_header_copy(commands, x:, y:, layout:)
    eyebrow = pdf_text("#{property.property_type} in #{property.location_line}")
    draw_text(commands, eyebrow, x:, y:, size: 10, font: :bold, color: COLORS[:brand_blue])

    line_y = y - 34
    address_lines = wrap_text(property.address_line_1, width: 238, font_size: 22, font: :bold, max_lines: 2)
    address_lines.each do |line|
      draw_text(commands, line, x:, y: line_y, size: 22, font: :bold, color: COLORS[:dark_text])
      line_y -= 24
    end

    headline_lines = layout.fetch(:headline_lines)
    headline_lines.each do |line|
      draw_text(commands, line, x:, y: line_y - 6, size: 13, font: :regular, color: COLORS[:body_text])
      line_y -= 16
    end
  end

  def draw_header_meta(commands, x:, layout:)
    draw_text(commands, hero_meta_line, x:, y: layout.fetch(:hero_meta_y), size: 10.5, font: :regular, color: COLORS[:muted_text])
    return if chronology_line.blank?

    draw_text(commands, chronology_line, x:, y: layout.fetch(:chronology_y), size: 10.5, font: :regular, color: COLORS[:muted_text])
  end

  def draw_price(commands, x:, y:)
    draw_text(commands, "Guide price", x:, y: y + 32, size: 9.5, font: :bold, color: COLORS[:brand_blue])
    draw_text(commands, formatted_currency(property.asking_price), x:, y:, size: 28, font: :bold, color: COLORS[:dark_text])
  end

  def draw_hero_image_panel(commands, hero_image:, x:, y:, width:, height:)
    draw_filled_rect(commands, x:, y:, width:, height:, fill: COLORS[:hero_image_background])
    draw_stroked_rect(commands, x:, y:, width:, height:, stroke: COLORS[:panel_border], line_width: 1)

    if hero_image.present?
      draw_image(commands, image: hero_image, x:, y:, width:, height:)
      draw_text(commands, "Primary property image", x: x + 10, y: y - 18, size: 10, font: :regular, color: COLORS[:muted_text])
    else
      draw_text(commands, "Image coming soon", x: x + 58, y: y + (height / 2) - 8, size: 14, font: :bold, color: COLORS[:brand_blue])
      draw_text(commands, "This sheet will use the listing hero image once it is attached.", x: x + 24, y: y + (height / 2) - 30, size: 10, font: :regular, color: COLORS[:muted_text])
    end
  end

  def draw_overview(commands, x:, y:)
    draw_text(commands, "Overview", x:, y:, size: 13, font: :bold, color: COLORS[:dark_text])

    description = property.property_description.to_s.squish
    description = description.truncate(460, omission: "...") if description.length > 460
    current_y = y - 26

    wrap_text(description, width: 286, font_size: 11.5, max_lines: 10).each do |line|
      draw_text(commands, line, x:, y: current_y, size: 11.5, font: :regular, color: COLORS[:body_text])
      current_y -= 17
    end

    draw_text(commands, "Prepared #{Date.current.strftime('%d %B %Y')}", x:, y: 172, size: 10, font: :regular, color: COLORS[:muted_text])
    draw_text(commands, "www.gotthekeys.com", x:, y: 156, size: 10, font: :bold, color: COLORS[:brand_blue])
  end

  def draw_key_facts(commands, x:, y:)
    draw_text(commands, "Key facts", x:, y:, size: 13, font: :bold, color: COLORS[:dark_text])

    facts_for_sheet.each_with_index do |(label, value), index|
      row_y = y - 28 - (index * 30)
      draw_text(commands, label.upcase, x:, y: row_y, size: 8.5, font: :bold, color: COLORS[:muted_text])
      draw_text(commands, value, x:, y: row_y - 12, size: 11, font: :bold, color: COLORS[:dark_text])
    end
  end

  def draw_contact_strip(commands, x:, y:, width:, height:)
    branch = AppSettings.primary_branch_profile

    draw_filled_rect(commands, x:, y:, width:, height:, fill: COLORS[:contact_background])
    draw_text(commands, branch.fetch(:name), x: x + 16, y: y + 33, size: 14, font: :bold, color: COLORS[:white])
    draw_text(commands, "#{branch.fetch(:phone)}  |  #{branch.fetch(:email)}", x: x + 214, y: y + 26, size: 10, font: :regular, color: COLORS[:white])
  end

  def hero_meta_line
    [
      bedrooms_label,
      "#{property.bathrooms} bath#{'s' unless property.bathrooms.to_i == 1}",
      property.town_city
    ].compact.join("  |  ")
  end

  def header_layout
    headline_lines = wrap_text(property.headline, width: 238, font_size: 13, max_lines: 3)
    address_lines = wrap_text(property.address_line_1, width: 238, font_size: 22, font: :bold, max_lines: 2)
    address_bottom_y = 652 - 34 - (24 * address_lines.length)
    headline_bottom_y = address_bottom_y - (16 * headline_lines.length)
    price_y = [headline_bottom_y - 42, 522].min
    hero_meta_y = price_y - 58
    chronology_y = hero_meta_y - 17

    {
      headline_lines:,
      price_y:,
      hero_meta_y:,
      chronology_y:
    }
  end

  def chronology_line
    parts = []
    parts << "Updated #{property.refurbished_year}" if property.refurbished_year.present?
    parts << area_label if area_label.present?
    parts.compact.join("  |  ")
  end

  def facts_for_sheet
    [
      ["Price", formatted_currency(property.asking_price)],
      ["Bedrooms", bedrooms_label],
      ["Bathrooms", property.bathrooms.to_i.to_s],
      ["Town", property.town_city],
      ["Postcode", property.postcode],
      ["Type", property.property_type],
      ["Area", area_label],
      ["Updated", property.refurbished_year&.to_s],
      ["Available", availability_label],
      ["Tenure", property.tenure],
      ["Parking", property.parking]
    ].select { |_label, value| value.present? }.first(8)
  end

  def bedrooms_label
    property.bedrooms.to_i.zero? ? "Studio" : "#{property.bedrooms} bedroom#{'s' unless property.bedrooms.to_i == 1}"
  end

  def area_label
    "#{property.floor_area_sq_ft} sq ft" if property.floor_area_sq_ft.present?
  end

  def availability_label
    if property.available_from.present?
      property.available_from.strftime("%d %b %Y")
    else
      "Available now"
    end
  end

  def formatted_currency(amount)
    number_to_currency(amount, unit: "£", precision: 0)
  end

  def hero_image_asset
    file_path = hero_image_path
    return if file_path.blank?

    case file_path.extname.downcase
    when ".jpg", ".jpeg"
      build_jpeg_image_asset(file_path)
    when ".png"
      build_png_image_asset(file_path)
    when ".webp"
      build_webp_image_asset(file_path)
    end
  end

  def hero_image_path
    image_name = property.hero_image_name.to_s
    return if image_name.blank?

    [retina_variant_name(image_name), image_name].compact.map { |candidate| Rails.root.join("app/assets/images", candidate) }.find(&:exist?)
  end

  def retina_variant_name(image_name)
    extension = File.extname(image_name)
    return if extension.blank?

    image_name.sub(/#{Regexp.escape(extension)}\z/i, "@2x#{extension}")
  end

  def build_jpeg_image_asset(path)
    width, height = jpeg_dimensions(path)
    {
      width:,
      height:,
      filter: "/DCTDecode",
      data: File.binread(path)
    }
  end

  def build_png_image_asset(path)
    image = ChunkyPNG::Image.from_file(path.to_s)
    pixels = +"".b

    image.height.times do |y|
      image.width.times do |x|
        pixel = image[x, y]
        alpha = ChunkyPNG::Color.a(pixel) / 255.0
        red = composite_channel(ChunkyPNG::Color.r(pixel), alpha)
        green = composite_channel(ChunkyPNG::Color.g(pixel), alpha)
        blue = composite_channel(ChunkyPNG::Color.b(pixel), alpha)

        pixels << red.chr << green.chr << blue.chr
      end
    end

    {
      width: image.width,
      height: image.height,
      filter: "/FlateDecode",
      data: Zlib::Deflate.deflate(pixels)
    }
  end

  def build_webp_image_asset(path)
    Tempfile.create(["property-document-image", ".png"]) do |png_file|
      png_path = png_file.path
      png_file.close

      success = system("dwebp", path.to_s, "-quiet", "-o", png_path)
      return unless success && File.exist?(png_path)

      build_png_image_asset(Pathname(png_path))
    end
  end

  def composite_channel(channel, alpha)
    ((channel * alpha) + (255 * (1.0 - alpha))).round
  end

  def jpeg_dimensions(path)
    bytes = File.binread(path)
    offset = 2

    while offset < bytes.bytesize
      offset += 1 while offset < bytes.bytesize && bytes.getbyte(offset) == 0xFF
      marker = bytes.getbyte(offset)
      offset += 1
      next if marker.nil? || marker == 0xD8 || marker == 0xD9

      length = bytes.byteslice(offset, 2).unpack1("n")
      offset += 2

      if sof_marker?(marker)
        height = bytes.byteslice(offset + 1, 2).unpack1("n")
        width = bytes.byteslice(offset + 3, 2).unpack1("n")
        return [width, height]
      end

      offset += length - 2
    end

    [768, 512]
  end

  def sof_marker?(marker)
    [0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF].include?(marker)
  end

  def draw_image(commands, image:, x:, y:, width:, height:)
    scale = [width / image.fetch(:width).to_f, height / image.fetch(:height).to_f].min
    draw_width = image.fetch(:width) * scale
    draw_height = image.fetch(:height) * scale
    draw_x = x + ((width - draw_width) / 2.0)
    draw_y = y + ((height - draw_height) / 2.0)

    commands << "q\n"
    commands << "#{fmt(draw_width)} 0 0 #{fmt(draw_height)} #{fmt(draw_x)} #{fmt(draw_y)} cm\n"
    commands << "/Im1 Do\nQ\n"
  end

  def draw_text(commands, text, x:, y:, size:, font:, color:)
    commands << "BT\n"
    commands << "/#{font_name(font)} #{fmt(size)} Tf\n"
    commands << "#{color_command(color)} rg\n"
    commands << "#{fmt(x)} #{fmt(y)} Td\n"
    commands << "(#{escape_pdf_text(text)}) Tj\n"
    commands << "ET\n"
  end

  def draw_filled_rect(commands, x:, y:, width:, height:, fill:)
    commands << "#{color_command(fill)} rg\n"
    commands << "#{fmt(x)} #{fmt(y)} #{fmt(width)} #{fmt(height)} re f\n"
  end

  def draw_stroked_rect(commands, x:, y:, width:, height:, stroke:, line_width:)
    commands << "#{color_command(stroke)} RG\n"
    commands << "#{fmt(line_width)} w\n"
    commands << "#{fmt(x)} #{fmt(y)} #{fmt(width)} #{fmt(height)} re S\n"
  end

  def draw_line(commands, x1:, y1:, x2:, y2:, color:, line_width:)
    commands << "#{color_command(color)} RG\n"
    commands << "#{fmt(line_width)} w\n"
    commands << "#{fmt(x1)} #{fmt(y1)} m #{fmt(x2)} #{fmt(y2)} l S\n"
  end

  def wrap_text(text, width:, font_size:, font: :regular, max_lines: nil)
    words = pdf_text(text).split(/\s+/)
    return [""] if words.empty?

    max_chars = [(width / (font_size * character_width_factor(font))).floor, 8].max
    lines = []
    current = +""

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

    if max_lines.present? && lines.length > max_lines
      lines = lines.first(max_lines)
      lines[-1] = lines.last.to_s.truncate(max_chars, omission: "...")
    end

    lines
  end

  def character_width_factor(font)
    font == :bold ? 0.58 : 0.52
  end

  def text_width(text, size, font)
    pdf_text(text).length * size * character_width_factor(font)
  end

  def font_name(font)
    font == :bold ? "F2" : "F1"
  end

  def color_command(color)
    color.map { |component| format("%.3f", component) }.join(" ")
  end

  def pdf_text(text)
    text.to_s.gsub("£", POUND_PLACEHOLDER).then { |value| I18n.transliterate(value) }.gsub(POUND_PLACEHOLDER, "£")
  end

  def fmt(number)
    format("%.2f", number)
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

  def escape_pdf_text(text)
    pdf_text(text)
      .gsub("\\", "\\\\\\")
      .gsub("(", "\\(")
      .gsub(")", "\\)")
      .gsub("£") { "\\243" }
  end
end
